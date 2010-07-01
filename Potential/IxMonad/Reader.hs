{-# LANGUAGE
	NoImplicitPrelude,
	FunctionalDependencies,
	MultiParamTypeClasses,
	FlexibleInstances
	#-}
module Potential.IxMonad.Reader
	( IxMonadReader(..)
	, IxReaderT(..)
	) where

import Prelude( ($) )

import Potential.IxMonad.IxMonad


class (IxMonad m) => IxMonadReader r m | m -> r where
  ask :: m x x z ct r

newtype IxReaderT r m x y z ct a =
    IxReaderT { runIxReaderT :: r -> m x y z ct a }

instance IxMonadTrans (IxReaderT r) where
  lift op = IxReaderT $ \_ -> op

instance IxMonad m => IxMonad (IxReaderT r m) where
  mixedReturn a = lift $ mixedReturn a
  ixmNop rd f = IxReaderT $ \r -> runIxReaderT rd r `ixmNop` \a ->
				  runIxReaderT (f a) r
  rd >>= f = IxReaderT $ \r -> runIxReaderT rd r >>= \a -> runIxReaderT (f a) r

instance IxMonad m => IxMonadReader r (IxReaderT r m) where
  ask = IxReaderT $ \r -> return r


