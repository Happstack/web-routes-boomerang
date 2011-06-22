@web-routes-boomerang@ makes it easy to use write custom
pretty-printers and parsers for your URL types. Instead of writing a
parser and a separate pretty-printer you can specify both at once by
using the @boomerang@ library:

<http://hackage.haskell.org/package/boomerang>

This demo will show the basics of getting started.

First we need to enable some language extensions:

@{\-\# LANGUAGE TemplateHaskell, TypeOperators, OverloadedStrings \#-\} @

> {-# LANGUAGE TemplateHaskell, TypeOperators, OverloadedStrings #-}
> module Main where

Note in the imports that we hide @(id, (.))@ from the "Prelude" and
use the versions from "Control.Category" instead.

> import Prelude              hiding (id, (.))
> import Control.Category     (Category(id, (.)))
> import Control.Monad.Trans  (MonadIO(liftIO))
> import Text.Boomerang.TH    (derivePrinterParsers)
> import Web.Routes           (Site(..), RouteT(..), decodePathInfo, encodePathInfo, runSite, showURL)
> import Web.Routes.Boomerang (Router, (<>), (</>), int, parse1, toSiteRouteT, anyString, parseStrings)

Next we define a data type that represents our sitemap.

> -- | the routes
> data Sitemap
>    = Home
>    | UserOverview
>    | UserDetail Int
>    | Article Int String
>    deriving (Eq, Show)


To use the 'Sitemap' type with @boomerang@ we need to call 'derivePrinterParsers':

> $(derivePrinterParsers ''Sitemap)

That will create new combinators corresponding to the constructors for
'Sitemap'. They will be named, @rHome@, @rUserOverview@, etc.

Now we can specify how the 'Sitemap' type is mapped to a url and back:

> sitemap :: Router Sitemap
> sitemap =
>     (  rHome
>     <> "users" . users
>     <> rArticle . ("article" </> int . "-" . anyString)
>     )
>   where
>     users  =  rUserOverview
>            <> rUserDetail </> int

The mapping looks like this:

@
 \/                       \<=\> Home
 \/users                  \<=\> UserOverview
 \/users\//<int>/            \<=\> UserDetail /<int>/
 \/article\//<int>/-/<string>/ \<=\> Article /<int>/ /<string>/
@

Next we have our function which maps a parsed route to the handler for
that route. (There is nothing @boomerang@ specific about this
function):

> handle :: Sitemap -> RouteT Sitemap IO ()
> handle url =
>     case url of
>       _ -> do liftIO $ print url
>               s <- showURL url
>               liftIO $ putStrLn s

Normally the @case@ statement would match on the different constructors and map them to different handlers. But in this case we use the same handler for all constructors. Also, instead of running in the IO monad, we would typically use a web framework monad like Happstack's 'ServerPartT'.

The handler does two things:

 1. prints the parsed url

 2. unparses the url and prints it

We now have two pieces:

 1. 'sitemap' - which converts urls to the 'Sitemap' type and back

 2. 'handle' - which maps 'Sitemap' to handlers

We tie these two pieces together use 'toSiteRouteT':

> site :: Site Sitemap (IO ())
> site = toSiteRouteT handle sitemap

This gives as a standard 'Site' value that we can use with 'runSite'
or with framework specific wrappers like @implSite@.

If we were not using 'RouteT' then we could use @toSite@ instead.

Now we can create a simple test function that takes the path info part
of a url and runs our site:

> test :: String -- ^ path info of incoming url
>      -> IO ()
> test path = 
>     case runSite "" site path of
>       (Left e)   -> putStrLn e
>       (Right io) -> io

We can use it like this:

@
ghci> test "users/1"
UserDetail 1
users/1
@

Here is a simple wrapper to call test interactively:

> -- | interactively call 'test'
> main :: IO ()
> main = mapM_ test =<< fmap lines getContents
        
Here are two more helper functions you can use to experiment interactively:

> -- | a little function to test rendering a url
> showurl :: Sitemap -> String
> showurl url = 
>     let (ps, params) = formatPathSegments site url
>     in (encodePathInfo ps params)

> -- | a little function to test parsing a url
> testParse :: String -> Either String Sitemap
> testParse pathInfo = 
>     case parsePathSegments site $ decodePathInfo pathInfo of
>       (Left e)  -> Left (show e)
>       (Right a) -> Right a

