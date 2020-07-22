{-|
Module      : Helpers
Description : Provides a number of helper functions
-}
module Helpers (makeScaler) where

import ASTProcessor (FunctionData)

getMinMaxBounds :: Ord a => [a] -> (a, a)
getMinMaxBounds [] = undefined
getMinMaxBounds (x : xs)
  = foldl (\ (minV, maxV) v -> (min minV v, max maxV v)) (x, x) xs

-- | Given a list of items and an accessor, builds
-- | a scale function.
makeScaler :: (Ord b, Fractional b) => (a -> b) -> [a] -> (a -> b)
makeScaler accessor items = (\ a -> (accessor a - minV) / (maxV - minV))
  where (minV, maxV) = getMinMaxBounds (map accessor items)
