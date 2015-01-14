<?xml version="1.0" encoding="UTF-8"?>

<!--
FILE : latex_utilities_frag.xsl

CREATED : 23 May 2000

LAST MODIFIED : 7 August 2001

AUTHOR : Warren Hedley (w.hedley@auckland.ac.nz)
         Department of Engineering Science
         The University of Auckland

TERMS OF USE / COPYRIGHT : See the "Terms of Use" page on the Tools section
  of the physiome.org.nz website, at http://www.physiome.org.nz/

DESCRIPTION : This stylesheet contains a named template 
  "latex_util_escape_special_characters" that will perform the escaping 
  necessary on a piece of plain text that will get it to render verbatim
  when the LaTeX is compiled.

  IMPORTANT : This is by no means complete, and only includes some characters
  and/or strings that have cropped up frequently in the documents on the CellML
  website. More characters and/or strings can be added to the transformation
  by adding them in the <luf:special_characters> section. Note that order IS
  important.

CHANGES :
  26/07/2001 - WJH - added mu to the list of greek characters understood.
  07/08/2001 - WJH - added top two find-and-replace patterns for < and >.
-->

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
    xmlns:luf="http://www.physiome.org.nz/latex_utilities"
    xmlns:saxon="http://icl.com/saxon"
    exclude-result-prefixes="luf"
    extension-element-prefixes="luf">


<luf:special_characters>
  <!--
    These characters must be escaped by placing a backslash in front of them.
  -->
  <luf:char>_</luf:char>
  <luf:char>%</luf:char>
  <luf:char>$</luf:char>
  <luf:char>{</luf:char>
  <luf:char>}</luf:char>
  <luf:char>&amp;</luf:char>
  <luf:char>#</luf:char>

  <!--
    These characters and strings must be replaced by a string.
  -->
  <luf:find string="&lt;"    replace="\ensuremath{&lt;}" />
  <luf:find string="&gt;"    replace="\ensuremath{&gt;}" />
  <luf:find string="&#0177;" replace="\ensuremath{\pm}" />  <!-- plus/minus -->
  <luf:find string="&#0176;" replace="\ensuremath{^\circ}" />   <!-- degree -->
  <luf:find string="&#0169;" replace="\copyright" />
  <luf:find string="&#0182;" replace="\textparagraph" />
  <luf:find string="~"       replace="\ensuremath{\sim}" />
  <luf:find string="&#0160;" replace="~" />         <!-- non-breaking space -->
  <luf:find string="&#0945;" replace="\ensuremath{\alpha}" />
  <luf:find string="&#0946;" replace="\ensuremath{\beta}" />
  <luf:find string="&#0947;" replace="\ensuremath{\gamma}" />
  <luf:find string="&#0948;" replace="\ensuremath{\delta}" />
  <luf:find string="&#0956;" replace="\ensuremath{\mu}" />
  <luf:find string="--cwmllubs--" replace="\ensuremath{\backslash}" />
</luf:special_characters>


<xsl:variable name="this_document"
    select="document('')" />

<xsl:variable name="this_stylesheet"
    select="document('')/xsl:stylesheet" />

<xsl:variable name="special_characters"
    select="document('')/xsl:stylesheet/luf:special_characters" />


<xsl:template name="latex_util_escape_special_characters">
  <xsl:param name="input_text" />
<!--
<xsl:document href="this_document.xml" method="xml">
  <xsl:copy-of select="$this_document" />
</xsl:document>
<xsl:document href="this_stylesheet.xml" method="xml">
  <xsl:copy-of select="$this_stylesheet" />
</xsl:document>
<xsl:document href="special_characters.xml" method="xml">
  <xsl:copy-of select="$special_characters" />
</xsl:document>
<xsl:message terminate="yes" />
-->
  <!--
    First we escape all backslashes. We actually insert a placeholder
    string that we can then replace last.
  -->
  <xsl:variable name="blackslashes_replaced">
    <xsl:call-template name="latex_util_string_replace">
      <xsl:with-param name="input_text" select="$input_text" />
      <xsl:with-param name="find"       select="'\'" />
      <xsl:with-param name="replace"    select="'--cwmllubs--'" />
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="backslashes_inserted">
    <xsl:call-template name="latex_util_insert_backslashes">
      <xsl:with-param name="input_text" select="$blackslashes_replaced" />
    </xsl:call-template>
  </xsl:variable>

  <xsl:call-template name="latex_util_replace_strings">
    <xsl:with-param name="input_text" select="$backslashes_inserted" />
  </xsl:call-template>

</xsl:template>


<xsl:template name="latex_util_put_backslash_in_front_of_char">
  <xsl:param name="input_text" />
  <xsl:param name="special_char" />
<!--
<xsl:message>latex_util_put_backslash_in_front_of_char('<xsl:value-of select="$input_text" />', '<xsl:value-of select="$special_char" />')</xsl:message>
-->
  <xsl:choose>
    <xsl:when test="contains($input_text, $special_char)">
      <xsl:value-of select="substring-before($input_text, $special_char)" />
      <xsl:text>\</xsl:text>
      <xsl:value-of select="$special_char" />
      <xsl:call-template name="latex_util_put_backslash_in_front_of_char">
        <xsl:with-param name="input_text"
                        select="substring-after($input_text, $special_char)" />
        <xsl:with-param name="special_char" select="$special_char" />
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$input_text" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template name="latex_util_string_replace">
  <xsl:param name="input_text" />
  <xsl:param name="find" />
  <xsl:param name="replace" />
<!--
<xsl:message>latex_util_string_replace('<xsl:value-of select="$input_text" />', '<xsl:value-of select="$find" />', '<xsl:value-of select="$replace" />')</xsl:message>
-->
  <xsl:choose>
    <xsl:when test="contains($input_text, $find)">
      <xsl:value-of select="substring-before($input_text, $find)" />
      <xsl:value-of select="$replace" />
      <xsl:call-template name="latex_util_string_replace">
        <xsl:with-param name="input_text"
            select="substring-after($input_text, $find)" />
        <xsl:with-param name="find"    select="$find" />
        <xsl:with-param name="replace" select="$replace" />
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$input_text" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template name="latex_util_insert_backslashes">
  <xsl:param name="input_text" />
  <xsl:param name="char_index" select="1" />
<!--
<xsl:message>latex_util_insert_backslashes('<xsl:value-of select="$input_text" />', '<xsl:value-of select="$char_index" />')</xsl:message>
-->
<xsl:variable name="text_escaping_instructions"
    select="document('')/xsl:stylesheet/luf:special_characters" />
<!--

<xsl:message>$text_escaping_instructions = <xsl:copy-of select="$text_escaping_instructions" /></xsl:message>

<xsl:message>$text_escaping_instructions/luf:char = <xsl:copy-of select="$text_escaping_instructions/luf:char" /></xsl:message>

<xsl:message>=> about to call latex_util_put_backslash_in_front_of_char(<xsl:value-of select="$input_text" />', '<xsl:value-of select="$text_escaping_instructions/luf:char[$char_index]" />')</xsl:message>
-->
  <xsl:variable name="current_char_escaped">
    <xsl:call-template name="latex_util_put_backslash_in_front_of_char">
      <xsl:with-param name="input_text" select="$input_text" />
      <xsl:with-param name="special_char"
          select="$text_escaping_instructions/luf:char[$char_index]" />
    </xsl:call-template>
  </xsl:variable>
  <xsl:choose>
    <xsl:when test="$char_index &lt;
        count($text_escaping_instructions/luf:char)">
      <xsl:call-template name="latex_util_insert_backslashes">
        <xsl:with-param name="input_text" select="$current_char_escaped" />
        <xsl:with-param name="char_index" select="$char_index + 1" />
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$current_char_escaped" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template name="latex_util_replace_strings">
  <xsl:param name="input_text" />
  <xsl:param name="string_index" select="1" />
<!--
<xsl:message>latex_util_insert_backslashes('<xsl:value-of select="$input_text" />', '<xsl:value-of select="$string_index" />')</xsl:message>
-->
<xsl:variable name="text_escaping_instructions"
    select="document('')/xsl:stylesheet/luf:special_characters" />

  <xsl:variable name="current_string_replaced">
    <xsl:call-template name="latex_util_string_replace">
      <xsl:with-param name="input_text" select="$input_text" />
      <xsl:with-param name="find"
          select="$text_escaping_instructions/luf:find[$string_index]/@string"
          />
      <xsl:with-param name="replace"
          select="$text_escaping_instructions/luf:find[$string_index]/@replace"
          />
    </xsl:call-template>
  </xsl:variable>
  <xsl:choose>
    <xsl:when test="$string_index &lt;
        count($text_escaping_instructions/luf:find)">
      <xsl:call-template name="latex_util_replace_strings">
        <xsl:with-param name="input_text" select="$current_string_replaced" />
        <xsl:with-param name="string_index" select="$string_index + 1" />
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$current_string_replaced" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


</xsl:stylesheet>
