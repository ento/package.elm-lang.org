{-# OPTIONS_GHC -Wall #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
module ServeFile
  ( misc
  , project
  , version
  )
  where


import qualified Data.ByteString.Builder as B
import qualified Data.Map as Map
import Data.Monoid ((<>))
import qualified Data.Text as Text
import Data.Time.Clock.POSIX (getPOSIXTime)
import Snap.Core (Snap, writeBuilder)
import System.IO.Unsafe (unsafePerformIO)
import Text.RawString.QQ (r)

import qualified Elm.Compiler.Module as Module
import qualified Elm.Package as Pkg



-- TYPICAL PAGES / NO PORTS


misc :: B.Builder -> Snap ()
misc title =
  makeHtml title mempty



-- PROJECT


project :: Pkg.Name -> Snap ()
project pkg =
  makeHtml (B.stringUtf8 (Pkg.toString pkg)) mempty



-- VERSION


version :: Pkg.Name -> Pkg.Version -> Maybe Module.Raw -> Snap ()
version pkg@(Pkg.Name _ prjct) vsn maybeName =
  let
    versionString =
      Pkg.versionToString vsn

    maybeStringName =
      fmap Module.nameToString maybeName

    title =
      maybe "" (++" - ") maybeStringName
      ++ Text.unpack prjct ++ " " ++ versionString
  in
  makeHtml (B.stringUtf8 title) (makeCanonicalLink pkg maybeName)



-- CANONICAL LINKS


makeCanonicalLink :: Pkg.Name -> Maybe Module.Raw -> B.Builder
makeCanonicalLink pkg maybeName =
  let
    canonicalPackage =
      Map.findWithDefault pkg pkg renames
  in
  [r|<link rel="canonical" href="/packages/|]
    <> B.stringUtf8 (Pkg.toUrl canonicalPackage)
    <> [r|/latest/|]
    <> maybe "" (B.stringUtf8 . Module.nameToString) maybeName
    <> [r|">|]


renames :: Map.Map Pkg.Name Pkg.Name
renames =
  Map.fromList
    [ Pkg.Name "evancz" "elm-effects" ==> Pkg.Name "elm" "core"
    , Pkg.Name "evancz" "elm-html" ==> Pkg.Name "elm" "html"
    , Pkg.Name "evancz" "elm-http" ==> Pkg.Name "elm" "http"
    , Pkg.Name "evancz" "elm-svg" ==> Pkg.Name "elm" "svg"
    , Pkg.Name "evancz" "start-app" ==> Pkg.Name "elm" "html"
    , Pkg.Name "evancz" "virtual-dom" ==> Pkg.Name "elm" "virtual-dom"

    , Pkg.Name "elm-lang" "animation-frame" ==> Pkg.Name "elm" "browser"
    , Pkg.Name "elm-lang" "core" ==> Pkg.Name "elm" "core"
    , Pkg.Name "elm-lang" "html" ==> Pkg.Name "elm" "html"
    , Pkg.Name "elm-lang" "http" ==> Pkg.Name "elm" "http"
    , Pkg.Name "elm-lang" "svg" ==> Pkg.Name "elm" "svg"
    , Pkg.Name "elm-lang" "virtual-dom" ==> Pkg.Name "elm" "virtual-dom"

    , Pkg.Name "elm-community" "elm-list-extra" ==> Pkg.Name "elm-community" "list-extra"
    , Pkg.Name "elm-community" "elm-linear-algebra" ==> Pkg.Name "elm-community" "linear-algebra"
    , Pkg.Name "elm-community" "elm-lazy-list" ==> Pkg.Name "elm-community" "lazy-list"
    , Pkg.Name "elm-community" "elm-json-extra" ==> Pkg.Name "elm-community" "json-extra"
    ]


(==>) :: a -> b -> (a, b)
(==>) =
  (,)



-- SKELETON


makeHtml :: B.Builder -> B.Builder -> Snap ()
makeHtml title canonicalLink =
  writeBuilder $
    [r|<!DOCTYPE HTML>
<html>
<head>
  <meta charset="UTF-8">
  <link rel="shortcut icon" size="16x16, 32x32, 48x48, 64x64, 128x128, 256x256" href="/assets/favicon.ico">
  <title>|] <> title <> [r|</title>|] <> canonicalLink <> [r|
  <link rel="stylesheet" href="/assets/highlight/styles/default.css?|] <> uniqueToken <> [r|">
  <link rel="stylesheet" href="/assets/style.css?|] <> uniqueToken <> [r|">
  <script src="/assets/highlight/highlight.pack.js?|] <> uniqueToken <> [r|"></script>
  <script src="/artifacts/elm.js?|] <> uniqueToken <> [r|"></script>
</head>
<body>
<script>
Elm.Main.init();
</script>
</body>
</html>|]


uniqueToken :: B.Builder
uniqueToken =
  unsafePerformIO $
    do  time <- getPOSIXTime
        return $ B.string7 $ show (floor time :: Integer)
