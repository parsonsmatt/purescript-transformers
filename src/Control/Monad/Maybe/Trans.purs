-- | This module defines the `MaybeT` monad transformer.

module Control.Monad.Maybe.Trans
  ( MaybeT(..), runMaybeT, mapMaybeT
  , module Control.Monad.Trans
  ) where

import Prelude

import Control.Alt (class Alt)
import Control.Alternative (class Alternative)
import Control.Monad.Cont.Class (class MonadCont, callCC)
import Control.Monad.Eff.Class (class MonadEff, liftEff)
import Control.Monad.Error.Class (class MonadError, catchError, catchJust, throwError)
import Control.Monad.Reader.Class (class MonadReader, ask, local, reader)
import Control.Monad.Rec.Class (class MonadRec, forever, tailRec, tailRecM, tailRecM2, tailRecM3)
import Control.Monad.RWS.Class (class MonadRWS)
import Control.Monad.State.Class (class MonadState, get, gets, modify, put, state)
import Control.Monad.Trans (class MonadTrans, lift)
import Control.Monad.Writer.Class (class MonadWriter, censor, listen, listens, pass, tell, writer)
import Control.MonadPlus (class MonadPlus)
import Control.MonadZero (class MonadZero)
import Control.Plus (class Plus)

import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Monoid (class Monoid)
import Data.Tuple (Tuple(..))

-- | The `MaybeT` monad transformer.
-- |
-- | This monad transformer extends the base monad, supporting failure and alternation via
-- | the `MonadPlus` type class.
newtype MaybeT m a = MaybeT (m (Maybe a))

-- | Run a computation in the `MaybeT` monad.
runMaybeT :: forall m a. MaybeT m a -> m (Maybe a)
runMaybeT (MaybeT x) = x

-- | Change the result type of a `MaybeT` monad action.
mapMaybeT :: forall m1 m2 a b. (m1 (Maybe a) -> m2 (Maybe b)) -> MaybeT m1 a -> MaybeT m2 b
mapMaybeT f (MaybeT m) = MaybeT (f m)

instance functorMaybeT :: Monad m => Functor (MaybeT m) where
  map = liftA1

instance applyMaybeT :: Monad m => Apply (MaybeT m) where
  apply = ap

instance applicativeMaybeT :: Monad m => Applicative (MaybeT m) where
  pure = MaybeT <<< pure <<< Just

instance bindMaybeT :: Monad m => Bind (MaybeT m) where
  bind (MaybeT x) f = MaybeT do
    v <- x
    case v of
      Nothing -> pure Nothing
      Just y -> case f y of
        MaybeT m -> m

instance monadMaybeT :: Monad m => Monad (MaybeT m)

instance monadTransMaybeT :: MonadTrans MaybeT where
  lift = MaybeT <<< liftM1 Just

instance altMaybeT :: Monad m => Alt (MaybeT m) where
  alt (MaybeT m1) (MaybeT m2) = MaybeT do
    m <- m1
    case m of
      Nothing -> m2
      ja -> pure ja

instance plusMaybeT :: Monad m => Plus (MaybeT m) where
  empty = MaybeT (pure Nothing)

instance alternativeMaybeT :: Monad m => Alternative (MaybeT m)

instance monadPlusMaybeT :: Monad m => MonadPlus (MaybeT m)

instance monadZeroMaybeT :: Monad m => MonadZero (MaybeT m)

instance monadRecMaybeT :: MonadRec m => MonadRec (MaybeT m) where
  tailRecM f =
    MaybeT <<< tailRecM \a ->
      case f a of
        MaybeT m -> m >>= \m' ->
          pure case m' of
            Nothing -> Right Nothing
            Just (Left a1) -> Left a1
            Just (Right b) -> Right (Just b)

instance monadEffMaybe :: MonadEff eff m => MonadEff eff (MaybeT m) where
  liftEff = lift <<< liftEff

instance monadContMaybeT :: MonadCont m => MonadCont (MaybeT m) where
  callCC f =
    MaybeT $ callCC \c -> case f (\a -> MaybeT $ c $ Just a) of MaybeT m -> m

instance monadErrorMaybeT :: MonadError e m => MonadError e (MaybeT m) where
  throwError e = lift (throwError e)
  catchError (MaybeT m) h =
    MaybeT $ catchError m (\a -> case h a of MaybeT b -> b)

instance monadReaderMaybeT :: MonadReader r m => MonadReader r (MaybeT m) where
  ask = lift ask
  local f = mapMaybeT (local f)

instance monadStateMaybeT :: MonadState s m => MonadState s (MaybeT m) where
  state f = lift (state f)

instance monadWriterMaybeT :: MonadWriter w m => MonadWriter w (MaybeT m) where
  writer wd = lift (writer wd)
  listen = mapMaybeT \m -> do
    Tuple a w <- listen m
    pure $ (\r -> Tuple r w) <$> a
  pass = mapMaybeT \m -> pass do
    a <- m
    pure case a of
      Nothing -> Tuple Nothing id
      Just (Tuple v f) -> Tuple (Just v) f

instance monadRWSMaybeT :: MonadRWS r w s m => MonadRWS r w s (MaybeT m)
