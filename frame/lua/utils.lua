--------------------------------------------------------------------------------
--
--  This file is part of the Doxyrest toolkit.
--
--  Doxyrest is distributed under the MIT license.
--  For details see accompanying license.txt file,
--  the public copy of which is also available at:
--  http://tibbo.com/downloads/archive/doxyrest/license.txt
--
--------------------------------------------------------------------------------

dofile(g_frameDir .. "/../common/string.lua")
dofile(g_frameDir .. "/../common/table.lua")
dofile(g_frameDir .. "/../common/item.lua")
dofile(g_frameDir .. "/../common/doc.lua")
dofile(g_frameDir .. "/../common/toc.lua")

if not INDEX_TITLE then
	INDEX_TITLE = "My Project Documentation"
end

if not EXTRA_PAGE_LIST then
	EXTRA_PAGE_LIST = {}
end

-------------------------------------------------------------------------------

-- formatting of function declarations

function getParamName(param)
	if param.declarationName ~= "" then
		return param.declarationName
	elseif param.definitionName ~= "" then
		return param.definitionName
	else
		return param.type.plainText
	end
end

function getParamArrayString_sl(paramArray)
	local s = "("

	local count = #paramArray
	if count > 0 then
		s = s .. getParamName(paramArray[1])

		for i = 2, count do
			s = s .. ", " .. getParamName(paramArray[i])
		end
	end

	s = s .. ")"
	return s
end

function getParamArrayString_ml(paramArray, indent)
	local s = "("

	if not indent then
		indent = ""
	end

	local nl = "\n" .. indent .. "    " -- rst code indent is 4 spaces

	local count = #paramArray
	if count > 0 then
		s = s .. nl .. getParamName(paramArray[1])

		for i = 2, count do
			s = s .. "," .. nl .. getParamName(paramArray[i])
		end
	end

	s = s .. nl .. ")"
	return s
end

function getFunctionDeclString(func, isRef, indent)
	local s = "function "

	if isRef then
		s = s .. ":ref:`" .. func.name  .. "<doxid-" .. func.id .. ">`"
	else
		s = s .. func.name
	end

	local paramString
	local space = ""

	if PRE_PARAM_LIST_SPACE then
		space = " "
	end

	if ML_PARAM_LIST_COUNT_THRESHOLD and
		#func.paramArray > ML_PARAM_LIST_COUNT_THRESHOLD then
		paramString = getParamArrayString_ml(func.paramArray, indent)
	else
		paramString = getParamArrayString_sl(func.paramArray)

		if ML_PARAM_LIST_LENGTH_THRESHOLD then
			local decl = "function " .. func.name .. space .. paramString
			if string.len(decl) > ML_PARAM_LIST_LENGTH_THRESHOLD then
				paramString = getParamArrayString_ml(func.paramArray, indent)
			end
		end
	end

	s = s .. space .. paramString
	return s
end

-------------------------------------------------------------------------------

-- compound prep

function itemLocationFilter(item)
	return not (item.location and string.match(item.location.file, EXCLUDE_LOCATION_PATTERN))
end

function prepareCompound(compound)
	if compound.stats then
		return compound.stats
	end

	local stats = {}

	if EXCLUDE_LOCATION_PATTERN then
		filterArray(compound.structArray, itemLocationFilter)
		filterArray(compound.variableArray, itemLocationFilter)
		filterArray(compound.functionArray, itemLocationFilter)
	end

	stats.hasItems =
		#compound.structArray ~= 0 or
		#compound.variableArray ~= 0 or
		#compound.functionArray ~= 0

	stats.hasBriefDocumentation = not isDocumentationEmpty(compound.briefDescription)
	stats.hasDetailedDocumentation = not isDocumentationEmpty(compound.detailedDescription)
	stats.hasDocumentedVariables = prepareItemArrayDocumentation(compound.variableArray, compound)
	stats.hasDocumentedFunctions = prepareItemArrayDocumentation(compound.functionArray, compound)
	stats.hasDocumentedItems = stats.hasDocumentedVariables or stats.hasDocumentedFunctions

	if EXCLUDE_UNDOCUMENTED_ITEMS then
		filterArray(compound.variableArray, hasItemRefTarget)
		filterArray(compound.functionArray, hasItemRefTarget)
	end

	table.sort(compound.groupArray, cmpIds)
	table.sort(compound.structArray, cmpNames)

	compound.stats = stats

	return stats
end

-------------------------------------------------------------------------------