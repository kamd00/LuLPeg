---------------------------------  ,--.                ,    ,--.            ---
---------------------------------  |__' ,  . ,--. ,--. |    |__' ,--. ,--.  ---
-- PureLPeg.lua -----------------  |    |  | |    |--' |    |    |--' `__|  ---
---------------------------------  '    `--' '    `--' `--- '    `--' .__'  ---

-- a WIP LPeg implementation in pure Lua, by Pierre-Yves Gérardy
-- released under the Romantic WTF Public License (see the end of the file).

-- Captures and locales are not yet implemented, but the rest works quite well.
-- UTF-8 is supported out of the box
--
--     PL.set_charset"UTF-8"
--     s = PL.S"ß∂ƒ©˙"
--     s:match"©" --> 3 (since © is two bytes wide).
-- 
-- More encodings can be easily added (see the charset section), by adding a 
-- few appropriate functions.

-- remove the global tables from the environment
-- they are restored at the end of the file.
-- standard libraries must be require()d.

--[[DBG]] local debug, print_ = require"debug", print
--[[DBG]] local print = function(...) 
--[[DBG]]    print_(debug.traceback(2))
--[[DBG]]    print_("RE print", ...)
--[[DBG]]    return ...
--[[DBG]] end

local tmp_globals, globalenv = {}, _ENV or _G
if false and not release then
for lib, tbl in pairs(globalenv) do
    if type(tbl) == "table" then
        tmp_globals[lib], globalenv[lib] = globalenv[lib], nil
    end
end
end

local getmetatable, pairs, setmetatable
    = getmetatable, pairs, setmetatable

local u = require"util"
local   map,   nop, t_unpack 
    = u.map, u.nop, u.unpack

-- The module decorators.
local API, charsets, compiler, constructors
    , datastructures, evaluator, factorizer
    , locale, match, printers, re
    = t_unpack(map(require,
    { "API", "charsets", "compiler", "constructors"
    , "datastructures", "evaluator", "factorizer"
    , "locale", "match", "printers", "re" }))

if not release then
    local success, package = pcall(require, "package")
    if type(package) == "table" 
    and type(package.loaded) == "table" 
    and package.loaded.re 
    then 
        package.loaded.re = nil
    end
end


local _ENV = u.noglobals() ----------------------------------------------------



-- The LPeg version we emulate.
local VERSION = "0.12"

-- The PureLPeg version.
local PVERSION = "0.0.0"

local CLI = function(lpeg, env) setmetatable(env,{__index = lpeg}) end

local 
function PLPeg(options)
    options = options and copy(options) or {}

    -- PL is the module
    -- Builder keeps the state during the module decoration.
    local Builder, PL 
        = { options = options, factorizer = factorizer }
        , { new = PLPeg
          , version = function () return VERSION end
          , pversion = function () return PVERSION end
          , setmaxstack = nop --Just a stub, for compatibility.
          }

    PL.__index = PL

    local
    function PL_ispattern(pt) return getmetatable(pt) == PL end
    PL.ispattern = PL_ispattern

    function PL.type(pt)
        if PL_ispattern(pt) then 
            return "pattern"
        else
            return nil
        end
    end
    PL.util = u
    PL.CLI = CLI
    -- Decorate the LPeg object.
    charsets(Builder, PL)
    datastructures(Builder, PL)
    printers(Builder, PL)
    constructors(Builder, PL)
    API(Builder, PL)
    evaluator(Builder, PL)
    ;(options.compiler or compiler)(Builder, PL)
    match(Builder, PL)
    locale(Builder, PL)
    PL.re = re(Builder, PL)

    return PL
end -- PLPeg

local PL = PLPeg()
-- restore the global libraries
for lib, tbl in pairs(tmp_globals) do
        globalenv[lib] = tmp_globals[lib] 
end


return PL

--                   The Romantic WTF public license.
--                   --------------------------------
--                   a.k.a. version "<3" or simply v3
--
--
--            Dear user,
--
--            The PureLPeg proto-library
--
--                                             \ 
--                                              '.,__
--                                           \  /
--                                            '/,__
--                                            /
--                                           /
--                                          /
--                       has been          / released
--                  ~ ~ ~ ~ ~ ~ ~ ~       ~ ~ ~ ~ ~ ~ ~ ~ 
--                under  the  Romantic   WTF Public License.
--               ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~`,´ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ 
--               I hereby grant you an irrevocable license to
--                ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
--                  do what the gentle caress you want to
--                       ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~  
--                           with   this   lovely
--                              ~ ~ ~ ~ ~ ~ ~ ~ 
--                               / thing...
--                              /  ~ ~ ~ ~
--                             /    Love,
--                        #   /      '.'
--                        #######      ·
--                        #####
--                        ###
--                        #
--
--            -- Pierre-Yves
--
--
--            P.S.: Even though I poured my heart into this work, 
--                  I _cannot_ provide any warranty regarding 
--                  its fitness for _any_ purpose. You
--                  acknowledge that I will not be held liable
--                  for any damage its use could incur.