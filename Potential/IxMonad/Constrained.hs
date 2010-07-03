{-# LANGUAGE
	NoImplicitPrelude,
	FunctionalDependencies,
	MultiParamTypeClasses,
	FlexibleInstances
	#-}
module Potential.IxMonad.Constrained
	( IxConstrainedT(..)
	) where

import Prelude( ($) )
import Potential.IxMonad.IxMonad

newtype IxConstrainedT c m x y z ct a =
    IxConstrainedT { runIxConstrainedT :: c -> m x y z ct a }

instance IxMonadTrans (IxConstrainedT c) where
  lift op = IxConstrainedT $ \c -> op

instance IxFunctor m => IxFunctor (IxConstrainedT c m) where
  fmap f m = IxConstrainedT $ \c -> fmap f (runIxConstrainedT m c)

instance IxMonad m => IxMonad (IxConstrainedT c m) where
  mixedReturn a = lift $ mixedReturn a
  st >>= f = IxConstrainedT $ \c -> runIxConstrainedT st c >>= \a ->
				    let st' = f a
				    in runIxConstrainedT st' c

