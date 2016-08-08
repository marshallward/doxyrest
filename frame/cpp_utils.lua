-------------------------------------------------------------------------------

function getNormalizedCppString (string, isCodeSnippet)
	local s = string

	if isCodeSnippet then
		s = string.gsub (s, "%s*%*", "*")
	else
		s = string.gsub (s, "%s*%*", "\\*")
	end

	if isCodeSnippet then
		s = string.gsub (s, "%s*&", "&")
	else
		s = string.gsub (s, "%s*&", "\\&")
	end

	if isCodeSnippet then
		s = string.gsub (s, "<%s*", " <")
	else
		s = string.gsub (s, "<%s*", " \\<")
	end

	s = string.gsub (s, "%s+>", ">")

	if isCodeSnippet then
		s = string.gsub (s, "%(%s*", " (")
	else
		s = string.gsub (s, "%(%s*", " \\(")
	end

	s = string.gsub (s, "%s+%)", ")")

	return s
end

function getLinkedTextString (text, isCodeSnippet)
	if not text then
		return nil
	end

	local s = ""

	for i = 1, #text.m_refTextArray do
		local refText = text.m_refTextArray [i]
		local text = getNormalizedCppString (refText.m_text, isCodeSnippet)

		if refText.m_id ~= "" then
			s = s .. ":ref:`" .. text .. "<doxid-" .. refText.m_id .. ">`"
		else
			s = s .. text
		end
	end

	return s
end

function getParamString (param, isCodeSnippet)
	local s = ""

	if not param.m_type.m_isEmpty then
		s = s .. getLinkedTextString (param.m_type, isCodeSnippet)
	end

	if param.m_declarationName ~= "" then
		if s ~= "" then
			s = s .. " "
		end

		s = s .. getNormalizedCppString (param.m_declarationName, isCodeSnippet)
	end

	if not param.m_defaultValue.m_isEmpty then
		s = s .. " = "
		s = s .. getLinkedTextString (param.m_defaultValue)
	end

	return s
end

function getFunctionParamArrayString (paramArray, isCodeSnippet)
	local s
	local count = #paramArray

	if count == 0 then
		s = "()"
	elseif count == 1 then
		s = "(" .. getParamString (paramArray [1], isCodeSnippet) .. ")"
	else
		s = "(\n\t\t"

		for i = 1, count do
			s = s .. getParamString (paramArray [i], isCodeSnippet)

			if i ~= count then
				s = s .. ","
			end

			s = s .. "\n\t\t"
		end
		s = s .. ")"
	end

	return s
end

function getTemplateParamArrayString (paramArray, isCodeSnippet)
	local s
	local count = #paramArray

	if count == 0 then
		s = "\\<>"
	else
		s = "\\<" .. getParamString (paramArray [1], isCodeSnippet)

		for i = 2, count do
			s = s .. ", " .. getParamString (paramArray [i], isCodeSnippet)
		end

		s = s .. ">"
	end

	return s
end

function getItemName (item)
	local s = item.m_name

	if item.m_templateParamArray and #item.m_templateParamArray > 0 then
		s = s .. " " .. getTemplateParamArrayString (item.m_templateParamArray)
	end

	if item.m_templateSpecParamArray and #item.m_templateSpecParamArray > 0 then
		s = s .. " " .. getTemplateParamArrayString (item.m_templateSpecParamArray)
	end

	return s
end

function getItemFileName (item, parentCompound)
	local s

	if item.m_compoundKind then
		s = item.m_compoundKind .. g_namespaceSep
	elseif item.m_memberKind then
		s = item.m_memberKind .. g_namespaceSep
	else
		s = "undef_"
	end

	if parentCompound.m_name then
		s = s .. string.gsub (parentCompound.m_path, "/", g_namespaceSep) .. g_namespaceSep
	end

	s = s .. item.m_name

	if item.m_templateSpecParamArray and #item.m_templateSpecParamArray > 0 then
		if not s_indexFormat then
			s_indexFormat = "%0" .. #tostring (g_indexedItemCount) + 1 .. "d"
		end

		s = s .. "_spec_" .. string.format (s_indexFormat, item.m_index)
	end

	s = s .. ".rst"

	return s
end

function getCompoundTocTree (compound, indent)
	local s = ""

	for i = 1, #compound.m_namespaceArray do
		local fileName = getItemFileName (compound.m_namespaceArray [i], compound)
		s = s .. indent .. fileName .. "\n"
	end

	for i = 1, #compound.m_enumArray do
		local fileName = getItemFileName (compound.m_enumArray [i], compound)
		s = s .. indent .. fileName .. "\n"
	end

	for i = 1, #compound.m_structArray do
		local fileName = getItemFileName (compound.m_structArray [i], compound)
		s = s .. indent .. fileName .. "\n"
	end

	for i = 1, #compound.m_unionArray do
		local fileName = getItemFileName (compound.m_unionArray [i], compound)
		s = s .. indent .. fileName .. "\n"
	end

	for i = 1, #compound.m_classArray do
		local fileName = getItemFileName (compound.m_classArray [i], compound)
		s = s .. indent .. fileName .. "\n"
	end

	return s
end

function getTitle (title, underline)
	return title .. "\n" .. string.rep (underline, #title)
end

function getMemberLabels (array)
	local s = ""

	for i = 1, #array do
		local item = array [i]
		s = s .. ".. _doxid-" .. item.m_id .. ":\n"
	end

	return s
end

-------------------------------------------------------------------------------

