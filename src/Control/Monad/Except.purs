
module Control.Monad.Except
  ( Except
  , runExcept
  , mapExcept
  , withExcept
  , module Control.Monad.Error.Class
  , module Trans
  ) where

import Prelude

import Control.Monad.Error.Class (class MonadError, throwError, catchError, catchJust)
import Control.Monad.Except.Trans (except) as Trans
import Control.Monad.Except.Trans (ExceptT(..), withExceptT, runExceptT, mapExceptT)

import Data.Either (Either)
import Data.Identity (Identity(..), runIdentity)

-- | A parametrizable exception monad; computations are either exceptions or
-- | pure values. If an exception is thrown (see `throwError`), the computation
-- | terminates with that value. Exceptions may also be caught with `catchError`,
-- | allowing the computation to resume and exit successfully.
-- |
-- | The type parameter `e` is the type of exceptions, and `a` is the type
-- | of successful results.
-- |
-- | A mechanism for trying many different computations until one succeeds is
-- | provided via the `Alt` instance, specifically the `(<|>)` function.
-- | The first computation to succeed is returned; if all fail, the exceptions
-- | are combined using their `Semigroup` instance. The `Plus` instance goes
-- | further and adds the possibility of a computation failing with an 'empty'
-- | exception; naturally, this requires the stronger constraint of a `Monoid`
-- | instance for the exception type.
type Except e a = ExceptT e Identity a

-- | Run a computation in the `Except` monad. The inverse of `except`.
runExcept :: forall e a. Except e a -> Either e a
runExcept = runIdentity <<< runExceptT

-- | Transform the unwrapped computation using the given function.
mapExcept :: forall e e' a b. (Either e a -> Either e' b) -> Except e a -> Except e' b
mapExcept f = mapExceptT (Identity <<< f <<< runIdentity)

-- | Transform any exceptions thrown by an `Except` computation using the given function.
withExcept :: forall e e' a. (e -> e') -> Except e a -> Except e' a
withExcept = withExceptT
