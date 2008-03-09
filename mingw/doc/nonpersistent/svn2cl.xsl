<?xml version="1.0" encoding="utf-8"?>

<!--

   svn2cl.xsl - xslt stylesheet for converting svn log to a normal
                changelog

   Usage (replace ++ with two minus signs):
     svn ++verbose ++xml log | \
       xsltproc ++stringparam strip-prefix `basename $(pwd)` \
                ++stringparam linelen 75 \
                ++stringparam groupbyday yes \
                ++stringparam include-rev yes \
                svn2cl.xsl - > ChangeLog

   This file is based on several implementations of this conversion
   that I was not completely happy with and some other common
   xslt constructs found on the web.

   Copyright (C) 2004, 2005 Arthur de Jong.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:
   1. Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
   2. Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the
      distribution.
   3. The name of the author may not be used to endorse or promote
      products derived from this software without specific prior
      written permission.

   THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
   IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
   ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
   DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
   DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
   GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
   IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
   IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

-->

<!DOCTYPE page [
 <!ENTITY tab "&#9;">
 <!ENTITY newl "&#13;">
 <!ENTITY space "&#32;">
]>

<!--
   TODO
   - make external lookups of author names possible
   - find a place for revision numbers
   - mark deleted files as such
   - combine paths
   - make path formatting nicer
-->

<xsl:stylesheet
  version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml">

 <xsl:output
   method="text"
   encoding="iso-8859-15"
   media-type="text/plain"
   omit-xml-declaration="yes"
   standalone="yes"
   indent="no" />

 <xsl:strip-space elements="*" />

 <!-- the prefix of pathnames to strip -->
 <xsl:param name="strip-prefix" select="'/'" />

 <!-- the length of a line to wrap messages at -->
 <xsl:param name="linelen" select="75" />
 
 <!-- whether entries should be grouped by day -->
 <xsl:param name="groupbyday" select="'no'" />

 <!-- whether entries should be grouped by day -->
 <xsl:param name="include-rev" select="'no'" />

 <!-- add newlines at the end of the changelog -->
 <xsl:template match="log">
  <xsl:apply-templates/>
  <xsl:text>&newl;</xsl:text>
 </xsl:template>

 <!-- format one entry from the log -->
 <xsl:template match="logentry">
  <!-- save log entry number -->
  <xsl:variable name="pos" select="position()"/>
  <!-- fetch previous entry's date -->
  <xsl:variable name="prevdate">
   <xsl:apply-templates select="../logentry[position()=(($pos)-1)]/date"/>
  </xsl:variable>
  <!-- fetch previous entry's author -->
  <xsl:variable name="prevauthor">
   <xsl:apply-templates select="../logentry[position()=(($pos)-1)]/author"/>
  </xsl:variable>
  <!-- fetch this entry's date -->
  <xsl:variable name="date">
   <xsl:apply-templates select="date" />
  </xsl:variable>
  <!-- fetch this entry's author -->
  <xsl:variable name="author">
   <xsl:apply-templates select="author" />
  </xsl:variable>
  <!-- check if header is changed -->
  <xsl:if test="($prevdate!=$date) or ($prevauthor!=$author)">
   <!-- add newline -->
   <xsl:if test="not(position()=1)">
     <xsl:text>&newl;</xsl:text>
   </xsl:if>
   <!-- date -->
   <xsl:apply-templates select="date" />
   <!-- two spaces -->
   <xsl:text>&space;&space;</xsl:text>
   <!-- author's name -->
   <xsl:apply-templates select="author" />
   <!-- two newlines -->
   <xsl:text>&newl;&newl;</xsl:text>
  </xsl:if>
  <!-- get paths string -->
  <xsl:variable name="paths">
   <xsl:apply-templates select="paths" />
  </xsl:variable>
  <!-- get revision number -->
  <xsl:variable name="rev">
   <xsl:if test="$include-rev='yes'">
    <xsl:text>[r</xsl:text>
    <xsl:value-of select="@revision"/>
    <xsl:text>]&space;</xsl:text>
   </xsl:if>
  </xsl:variable>
  <!-- first line is indented (other indents are done in wrap template) -->
  <xsl:text>&tab;*&space;</xsl:text>
  <!-- print the paths and message nicely wrapped -->
  <xsl:call-template name="wrap">
   <xsl:with-param name="txt" select="concat($rev,$paths,normalize-space(msg))" />
  </xsl:call-template>
 </xsl:template>

 <!-- format date -->
 <xsl:template match="date">
  <xsl:variable name="date" select="normalize-space(.)" />
  <!-- output date part -->
  <xsl:value-of select="substring($date,1,10)" />
  <!-- output time part -->
  <xsl:if test="$groupbyday!='yes'">
   <xsl:text>&space;</xsl:text>
   <xsl:value-of select="substring($date,12,5)" />
  </xsl:if>
 </xsl:template>

 <!-- format author -->
 <xsl:template match="author">
  <xsl:value-of select="normalize-space(.)" />
 </xsl:template>

 <!-- present a list of paths names -->
 <xsl:template match="paths">
  <xsl:for-each select="path">
   <xsl:sort select="normalize-space(.)" data-type="text" />
   <!-- unless we are the first entry, add a comma -->
   <xsl:if test="not(position()=1)">
    <xsl:text>,&space;</xsl:text>
   </xsl:if>
   <!-- print the path name -->
   <xsl:apply-templates select="."/>
  </xsl:for-each>
  <!-- end the list with a colon -->
  <xsl:text>:&space;</xsl:text>
 </xsl:template>

 <!-- transform path to something printable -->
 <xsl:template match="path">
  <!-- fetch the pathname -->
  <xsl:variable name="p1" select="normalize-space(.)" />
  <!-- strip leading slash -->
  <xsl:variable name="p2">
   <xsl:choose>
    <xsl:when test="starts-with($p1,'/')">
     <xsl:value-of select="substring($p1,2)" />
    </xsl:when>
    <xsl:otherwise>
     <xsl:value-of select="$p1" />
    </xsl:otherwise>
   </xsl:choose>
  </xsl:variable>
  <!-- strip trailing slash from strip-prefix -->
  <xsl:variable name="sp">
   <xsl:choose>
    <xsl:when test="substring($strip-prefix,string-length($strip-prefix),1)='/'">
     <xsl:value-of select="substring($strip-prefix,1,string-length($strip-prefix)-1)" />
    </xsl:when>
    <xsl:otherwise>
     <xsl:value-of select="$strip-prefix" />
    </xsl:otherwise>
   </xsl:choose>
  </xsl:variable>
  <!-- strip strip-prefix -->
  <xsl:variable name="p3">
   <xsl:choose>
    <xsl:when test="starts-with($p2,$sp)">
     <xsl:value-of select="substring($p2,1+string-length($sp))" />
    </xsl:when>
    <xsl:otherwise>
     <!-- TODO: do not print strings that do not begin with strip-prefix -->
     <xsl:value-of select="$p2" />
    </xsl:otherwise>
   </xsl:choose>
  </xsl:variable>
  <!-- strip another slash -->
  <xsl:variable name="p4">
   <xsl:choose>
    <xsl:when test="starts-with($p3,'/')">
     <xsl:value-of select="substring($p3,2)" />
    </xsl:when>
    <xsl:otherwise>
     <xsl:value-of select="$p3" />
    </xsl:otherwise>
   </xsl:choose>
  </xsl:variable>
  <!-- translate empty string to dot -->
  <xsl:choose>
   <xsl:when test="$p4 = ''">
    <xsl:text>.</xsl:text>
   </xsl:when>
   <xsl:otherwise>
    <xsl:value-of select="$p4" />
   </xsl:otherwise>
  </xsl:choose>
 </xsl:template>

 <!-- string-wrapping template -->
 <xsl:template name="wrap">
  <xsl:param name="txt" />
  <xsl:choose>
   <xsl:when test="(string-length($txt) &lt; (($linelen)-9)) or not(contains($txt,' '))">
    <!-- this is easy, nothing to do -->
    <xsl:value-of select="$txt" />
    <!-- add newline -->
    <xsl:text>&newl;</xsl:text>
   </xsl:when>
   <xsl:otherwise>
    <!-- find the first line -->
    <xsl:variable name="tmp" select="substring($txt,1,(($linelen)-10))" />
    <xsl:variable name="line">
     <xsl:choose>
      <xsl:when test="contains($tmp,' ')">
       <xsl:call-template name="find-line">
        <xsl:with-param name="txt" select="$tmp" />
       </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
       <xsl:value-of select="substring-before($txt,' ')" />
      </xsl:otherwise>
     </xsl:choose>
    </xsl:variable>
    <!-- print newline and tab -->
    <xsl:value-of select="$line" />
    <xsl:text>&newl;&tab;&space;&space;</xsl:text>
    <!-- wrap the rest of the text -->
    <xsl:call-template name="wrap">
     <xsl:with-param name="txt" select="normalize-space(substring($txt,string-length($line)+1))" />
    </xsl:call-template>
   </xsl:otherwise>
  </xsl:choose>
 </xsl:template>

 <!-- template to trim line to contain space as last char -->
 <xsl:template name="find-line">
  <xsl:param name="txt" />
  <xsl:choose>
   <xsl:when test="substring($txt,string-length($txt),1) = ' '">
    <xsl:value-of select="normalize-space($txt)" />
   </xsl:when>
   <xsl:otherwise>
    <xsl:call-template name="find-line">
     <xsl:with-param name="txt" select="substring($txt,1,string-length($txt)-1)" />
    </xsl:call-template>
   </xsl:otherwise>
  </xsl:choose>
 </xsl:template>

</xsl:stylesheet>
