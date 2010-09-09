{-
  Copyright 2010 Timothy Carstens    carstens@math.utah.edu

  This file is part of the Potential Standard Library.

    The Potential Standard Library is free software: you can redistribute it
    and/or modify it under the terms of the GNU Lesser General Public License as
    published by the Free Software Foundation, version 3 of the License.

    The Potential Standard Library is distributed in the hope that it will be
    useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with the Potential Standard Library.  If not, see
    <http://www.gnu.org/licenses/>.
-}
{-# LANGUAGE
	TemplateHaskell,
	DeriveDataTypeable #-}
module Language.Potential.DataStructure.AbstractSyntax where

import Prelude
import Data.Typeable
import Data.Data
import Data.List (nub)
import Data.Word (Word64(..))
import Data.Bits (complement, shiftL)
import Numeric (showHex)
import Text.PrettyPrint.Leijen
import qualified Language.Haskell.TH as TH
import qualified Language.Haskell.TH.Syntax as THS

type ByteOffset = Integer
type BitOffset  = Integer
type Partial = ([Field], ByteOffset)
type FieldWithBitOffset = (Field, BitOffset)

-- Types to model the struct we're going to defined
-- Instances are generated by the parser
data UserStruct =
     UserStruct { struct_name  :: String
		, constructors :: [Constructor]
		}
  deriving (Eq, Show, Data, Typeable)

instance Pretty UserStruct where
  pretty us = (text "data " <+> pretty (struct_name us) <+> text " =")
		<$$> (nest 2 (prettyList (constructors us)))


data Constructor =
    Constructor { constr_name :: String
		, fields :: [Field]
		}
  deriving (Eq, Show, Data, Typeable)

instance Pretty Constructor where
  pretty c = pretty (constr_name c) <+> space
		<+> semiBraces (map pretty (fields c))
  prettyList [c] = nest 2 (pretty c)
  prettyList (c:cs) = prettyList [c] <$$> prettyList' cs
	where prettyList' cs = foldl (<+>) empty (map pretty' cs)
	      pretty' c = char '|' <+> nest 1 (pretty c) <+> linebreak


data FieldAccess =
    FieldAccess { maskIsolate :: Word64
		, maskForget  :: Word64
		, bytesIn :: Integer
		, bitsIn  :: Integer }
  deriving (Eq, Show, Data, Typeable)

instance Pretty FieldAccess where
  pretty f = text "Access:" <$$> nest 2 access
    where access =
	    text ("Isolate: " ++ showHex (fromIntegral $ maskIsolate f) "") <$$>
	    text ("Forget:  " ++ showHex (fromIntegral $ maskIsolate f) "") <$$>
	    text ("Bytes in: " ++ show (maskIsolate f)) <$$>
	    text ("Bits in:  " ++ show (maskIsolate f))

data Field =
    VarField { field_name   :: String
	     , field_size   :: Integer
	     , field_access :: FieldAccess }
  | ConstField { field_size   :: Integer
	       , field_val    :: [Bit]
	       , field_access :: FieldAccess }
  | ReservedField { field_size   :: Integer
		  , field_access :: FieldAccess }
  deriving (Eq, Show, Data, Typeable)

instance Pretty Field where
  pretty f@VarField{} = pretty (field_name f) <+> char ':'
				<+> pretty (field_size f)
  pretty f@ConstField{} = pretty "const" <+> space <+> prettyList (field_val f)
  pretty f@ReservedField{} = pretty "(reserved)" <+> char ':'
				<+> pretty (field_size f)



data Bit = ConstBit0 | ConstBit1
  deriving (Eq, Show, Data, Typeable)

instance Pretty Bit where
  pretty ConstBit0 = char '0'
  pretty ConstBit1 = char '1'



-- |Returns true if the given field is a VarField, else returns false.
isVarField :: Field -> Bool
isVarField a@VarField{} = True
isVarField _ = False

-- |Returns the list of var field names for a given list of fields.  Does not
-- contain repeats.
varFieldNames :: [Field] -> [String]
varFieldNames fs  = let varfs = filter isVarField fs
		    in nub $ map field_name varfs

-- |Given a UserStruct, yields the list of all fields across all constructors.
-- May contain repeats if multiple constructors have some fields in common.
allFields :: UserStruct -> [Field]
allFields us = concat $ map fields (constructors us)


-- |Given a constructor, fills in the 'field_access' record for every field.
-- Useful for struct definition parsers who don't want to calculate this stuff
-- themselves.
fieldAccess :: Constructor -> Constructor
fieldAccess c = c{ fields = defineAccess (0 :: Integer) (fields c) }
  where defineAccess bits [] = []
	defineAccess bits (f:fs) =
	    let f' = f{ field_access = a }
		a  = FieldAccess
			{ maskIsolate = im
			, maskForget  = fm
			, bytesIn = (fromIntegral bits) `div` 8
			, bitsIn  = fromIntegral bi }
		bi = (fromIntegral bits) `mod` 8
		im = (2^(field_size f) - 1) `shiftL` bi
		fm = complement im
	    in f' : defineAccess (bits + field_size f) fs


instance THS.Lift FieldAccess where
  lift a = foldl TH.appE [| FieldAccess |]
		[ THS.lift (fromIntegral $ maskIsolate a :: Integer)
		, THS.lift (fromIntegral $ maskForget a :: Integer)
		, THS.lift $ bytesIn a
		, THS.lift $ bitsIn a ]

instance THS.Lift Bit where
  lift ConstBit0 = [| ConstBit0 |]
  lift ConstBit1 = [| ConstBit1 |]

instance THS.Lift Field where
  lift f@VarField{} = foldl TH.appE [| VarField |]
				[ THS.lift $ field_name f
				, THS.lift $ field_size f]
  lift f@ConstField{} = foldl TH.appE [| ConstField |]
				[ THS.lift $ field_size f
				, THS.lift $ field_val f ]
  lift f@ReservedField{} = foldl TH.appE [| ReservedField |]
				[ THS.lift $ field_size f ]

instance THS.Lift Constructor where
  lift c = foldl TH.appE [| Constructor |]
			[ THS.lift $ constr_name c
			, THS.lift $ fields c ]

instance THS.Lift UserStruct where
  lift us = foldl TH.appE [| UserStruct |]
			[ THS.lift $ struct_name us
			, THS.lift $ constructors us ]

