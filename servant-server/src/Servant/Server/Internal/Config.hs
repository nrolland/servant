{-# LANGUAGE CPP                        #-}
{-# LANGUAGE DataKinds                  #-}
{-# LANGUAGE DeriveFoldable             #-}
{-# LANGUAGE DeriveFunctor              #-}
{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE DeriveTraversable          #-}
{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE FunctionalDependencies     #-}
{-# LANGUAGE GADTs                      #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE KindSignatures             #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE PolyKinds                  #-}
{-# LANGUAGE ScopedTypeVariables        #-}
{-# LANGUAGE TypeOperators              #-}
{-# LANGUAGE UndecidableInstances       #-}

#include "overlapping-compat.h"

module Servant.Server.Internal.Config where

import           Data.Proxy
import           GHC.TypeLits

-- | The entire configuration.
data Config a where
    EmptyConfig :: Config '[]
    (:.) :: x -> Config xs -> Config (x ': xs)
infixr 5 :.

instance Show (Config '[]) where
  show EmptyConfig = "EmptyConfig"
instance (Show a, Show (Config as)) => Show (Config (a ': as)) where
  showsPrec outerPrecedence (a :. as) =
    showParen (outerPrecedence > 5) $
      shows a . showString " :. " . shows as

instance Eq (Config '[]) where
    _ == _ = True
instance (Eq a, Eq (Config as)) => Eq (Config (a ': as)) where
    x1 :. y1 == x2 :. y2 = x1 == x2 && y1 == y2

class HasConfigEntry (cfg :: [*]) (val :: *) where
    getConfigEntry :: Config cfg -> val

instance OVERLAPPABLE_
         HasConfigEntry xs val => HasConfigEntry (notIt ': xs) val where
    getConfigEntry (_ :. xs) = getConfigEntry xs

instance OVERLAPPABLE_
         HasConfigEntry (val ': xs) val where
    getConfigEntry (x :. _) = x

-- * support for subconfigs

data SubConfig (name :: Symbol) (subConfig :: [*])
  = SubConfig (Config subConfig)

descendIntoSubConfig :: forall config name subConfig .
  HasConfigEntry config (SubConfig name subConfig) =>
  Proxy (name :: Symbol) -> Config config -> Config subConfig
descendIntoSubConfig Proxy config =
  let SubConfig subConfig = getConfigEntry config :: SubConfig name subConfig
  in subConfig
