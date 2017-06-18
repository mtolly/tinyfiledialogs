module Graphics.UI.TinyFileDialogs
( DialogType(..)
, IconType(..)
, messageBox
, inputBox
, saveFileDialog
, openFileDialog
, selectFolderDialog
, colorChooser
) where

import           Data.Char          (toLower)
import qualified Data.Text          as T
import           Foreign            (Ptr, Word8, nullPtr, peekArray, withArray,
                                     withArrayLen, withMany)
import           Foreign.C          (CInt, CString, CUChar)

#ifdef WINDOWS
import qualified Data.ByteString    as B
import qualified Data.Text.Encoding as TE
#else
import           Foreign.C          (peekCString, withCString)
#endif

#include "tinyfiledialogs.h"

{#context prefix = "tinyfd_" #}

withCText :: T.Text -> (CString -> IO a) -> IO a
#ifdef WINDOWS
withCText = B.useAsCString . TE.encodeUtf8
#else
withCText = withCString . T.unpack
#endif

withCShowLower :: (Show a) => a -> (CString -> IO b) -> IO b
withCShowLower = withCText . T.pack . map toLower . show

withCMaybeText :: Maybe T.Text -> (CString -> IO a) -> IO a
withCMaybeText mt f = case mt of
  Nothing -> f nullPtr
  Just t  -> withCText t f

peekMaybeText :: CString -> IO (Maybe T.Text)
peekMaybeText cstr = if cstr == nullPtr
  then return Nothing
#ifdef WINDOWS
  -- TODO unicode: see encoding notes in inputBoxWinGui
  else fmap (Just . TE.decodeUtf8) $ B.packCString cstr
#else
  else fmap (Just . T.pack) $ peekCString cstr
#endif

peekMaybeTextMultiple :: CString -> IO (Maybe [T.Text])
peekMaybeTextMultiple = fmap (fmap $ T.splitOn (T.singleton '|')) . peekMaybeText

withCTexts :: [T.Text] -> ((CInt, Ptr CString) -> IO a) -> IO a
withCTexts ts f = withMany withCText ts $ \ptrs ->
  withArrayLen ptrs $ \len ptr -> f (fromIntegral len, ptr)

data DialogType = OK | OKCancel | YesNo
  deriving (Eq, Ord, Show, Read, Enum, Bounded)

data IconType = Info | Warning | Error | Question
  deriving (Eq, Ord, Show, Read, Enum, Bounded)

{#fun messageBox
  { withCText*      `T.Text'     -- ^ title
  , withCText*      `T.Text'     -- ^ message, may contain @\\n@ and @\\t@
  , withCShowLower* `DialogType'
  , withCShowLower* `IconType'
  ,                 `Bool'       -- ^ default button: 'False' for cancel\/no, 'True' for ok\/yes
  } -> `Bool' -- ^ 'False' for cancel\/no, 'True' for ok/yes
#}

{#fun inputBox
  { withCText*      `T.Text'       -- ^ title
  , withCText*      `T.Text'       -- ^ message, may NOT contain @\\n@ and @\\t@ on windows
  , withCMaybeText* `Maybe T.Text' -- ^ default input, if 'Nothing' it's a passwordBox
  } -> `Maybe T.Text' peekMaybeText* -- ^ returns 'Nothing' on cancel
#}

{#fun saveFileDialog
  { withCText*  `T.Text'    -- ^ title
  , withCText*  `T.Text'    -- ^ default path and file
  , withCTexts* `[T.Text]'& -- ^ filter patterns, @["*.jpg","*.png"]@
  , withCText*  `T.Text'    -- ^ single filter description, @"text files"@
  } -> `Maybe T.Text' peekMaybeText* -- ^ returns 'Nothing' on cancel
#}

{#fun openFileDialog
  { withCText*  `T.Text'    -- ^ title
  , withCText*  `T.Text'    -- ^ default path and file
  , withCTexts* `[T.Text]'& -- ^ filter patterns, @["*.jpg","*.png"]@
  , withCText*  `T.Text'    -- ^ single filter description, @"text files"@
  ,             `Bool'      -- ^ allow multiple selects
  } -> `Maybe [T.Text]' peekMaybeTextMultiple* -- ^ returns 'Nothing' on cancel
#}

{#fun selectFolderDialog
  { withCText* `T.Text' -- ^ title
  , withCText* `T.Text' -- ^ default path
  } -> `Maybe T.Text' peekMaybeText* -- ^ returns 'Nothing' on cancel
#}

{#fun colorChooser as c_colorChooser
  { withCText*      `T.Text'
  , withCMaybeText* `Maybe T.Text'
  , id              `Ptr CUChar'
  , id              `Ptr CUChar'
  } -> `Maybe T.Text' peekMaybeText* -- ^ returns 'Nothing' on cancel
#}

withColor :: (Word8, Word8, Word8) -> (Ptr CUChar -> IO a) -> IO a
withColor (r, g, b) = withArray $ map fromIntegral [r, g, b]

colorChooser
  :: T.Text                           -- ^ title
  -> (Word8, Word8, Word8)            -- ^ default RGB color
  -> IO (Maybe (Word8, Word8, Word8)) -- ^ returns 'Nothing' on cancel
colorChooser title color = withColor color $ \ptr -> do
  res <- c_colorChooser title Nothing ptr ptr
  case res of
    Nothing -> return Nothing
    Just _  -> fmap ((\[r, g, b] -> Just (r, g, b)) . map fromIntegral) $ peekArray 3 ptr
