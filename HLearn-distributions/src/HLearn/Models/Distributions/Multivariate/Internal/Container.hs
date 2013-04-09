{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE StandaloneDeriving #-}

-- | 
module HLearn.Models.Distributions.Multivariate.Internal.Container
    where

import HLearn.Algebra
import HLearn.Models.Distributions.Common

-------------------------------------------------------------------------------
-- data types

data Container dist sample basedist prob = Container    
    { dist :: dist prob
    , basedist :: basedist
    }
    deriving (Read,Show,Eq,Ord)

-------------------------------------------------------------------------------
-- Algebra

instance 
    ( Semigroup (dist prob)
    , Semigroup basedist
    ) => Semigroup (Container dist sample basedist prob) 
        where
    c1<>c2 = Container
        { dist = dist c1 <> dist c2
        , basedist = basedist c1 <> basedist c2
        }

instance 
    ( RegularSemigroup (dist prob)
    , RegularSemigroup basedist
    ) => RegularSemigroup (Container dist sample basedist prob) 
        where
    inverse c = Container
        { dist = inverse $ dist c
        , basedist = inverse $ basedist c
        }

instance 
    ( Monoid (dist prob)
    , Monoid basedist
    , Semigroup (Container dist sample basedist prob) 
    ) => Monoid (Container dist sample basedist prob) 
        where
    mempty = Container mempty mempty
    c1 `mappend` c2 = c1<>c2

instance 
    ( LeftOperator ring (dist prob)
    , LeftOperator ring basedist
    ) => LeftOperator ring (Container dist sample basedist prob) 
        where
    r .* c = Container
        { dist = r .* (dist c)
        , basedist = r .* (basedist c)
        }
        
instance 
    ( RightOperator ring (dist prob)
    , RightOperator ring basedist
    ) => RightOperator ring (Container dist sample basedist prob) 
        where
    c *. r = Container
        { dist = (dist c) *. r
        , basedist = (basedist c) *. r
        }

-------------------------------------------------------------------------------
-- Training

instance 
    ( ModelParams (dist prob)
    , ModelParams (basedist)
    , Params basedist ~ HList xs
    ) => ModelParams (Container dist sample basedist prob) 
        where
    type Params (Container dist sample basedist prob) = (Params (dist prob)) `HCons` (Params basedist)
    getparams c = (getparams $ dist c):::(getparams $ basedist c)
    
instance 
    ( HomTrainer (dist prob)
    , HomTrainer basedist
    , Params basedist ~ HList xs
    , Datapoint basedist ~ HList ys
    ) =>  HomTrainer (Container dist sample basedist prob) 
        where
    type Datapoint (Container dist sample basedist prob) = 
        (Datapoint (dist prob)) `HCons` (Datapoint basedist)
        
    train1dp' (distparams:::baseparams) (dp:::basedp) = Container
        { dist = train1dp' distparams dp
        , basedist = train1dp' baseparams basedp
        }

-------------------------------------------------------------------------------
-- Distribution
    
