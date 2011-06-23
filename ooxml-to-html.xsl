<!-- Converts an Open Office Writer document into HTML. Add a .zip extension 
     to the ODT file and extract the content.xml file to use as input.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml" version="2.0"
    xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
    xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
    xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0">
    
    <!-- Parameters -->
    <xsl:param name="folder"/>
    
    <!-- Global variables -->
    <xsl:variable name="CSS_FILE_NAME" select="'styles.css'"/>
    <xsl:variable name="style-path" select="concat($folder, '/', 'styles.xml')"/>
    
    <!-- Stripping excessive white space -->
    <xsl:strip-space elements="office:*"/>
    <xsl:strip-space elements="text:p"/>
    <xsl:strip-space elements="table:*"/>
    
    <xsl:output method="xml" doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
        doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"  
        indent="yes"        
        encoding="UTF-8"/>

    <xsl:template match="office:document-content">
        <xsl:apply-templates/> 
    </xsl:template>
    
    <xsl:template match="office:automatic-styles"/>
    
    <xsl:template match="office:body">
        <html>
            <head>
                <title>
                    <xsl:value-of select="office:text/text:h[1]"/>
                </title>
                <link type="text/css" href="{$CSS_FILE_NAME}" rel="stylesheet" media="all"/>
            </head>
            <body>
                <xsl:apply-templates/>
                <xsl:call-template name="Notes"/>
            </body>
        </html>
    </xsl:template>
    
    <xsl:template match="office:text">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="text:sequence-decls"/>
    
    <!-- *** Templates for lower-level text mark-up *** -->
    <!-- Headings -->
    <xsl:template match="text:h">
        <!-- Ignore empty heading tags -->
        <xsl:if test="string-length(.)>0">
            <xsl:choose>
                <xsl:when test="@text:outline-level=1">
                    <h1><xsl:apply-templates/></h1>
                </xsl:when>
                <xsl:when test="@text:outline-level=2">                  
                    <h2><xsl:apply-templates/></h2>
                </xsl:when>
                <xsl:when test="@text:outline-level=3">
                    <h3><xsl:apply-templates/></h3>
                </xsl:when>
                <xsl:otherwise>
                    <h4><xsl:apply-templates/></h4>
                </xsl:otherwise>           
            </xsl:choose>         
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="text:line-break">
        <br/>
    </xsl:template>
    
    <!-- Lists -->
    <xsl:template match="text:list">
        <xsl:variable name="list_style" select="@text:style-name"/>
        <!-- Look up style to find out whether this is an ordered or unordered list -->
        <xsl:variable name="style_contents" 
            select="document($style-path)/office:document-styles/office:styles/text:list-style[@style:name=$list_style]"/>
        <xsl:choose>
            <xsl:when test="$style_contents/text:list-level-style-bullet">
                <ul>
                    <xsl:apply-templates/>
                </ul>
            </xsl:when>
            <xsl:when test="$style_contents/text:list-level-style-number">
                <ol>
                    <xsl:apply-templates/>
                </ol>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>Error: unknown list type</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="text:list-item">
        <li><xsl:apply-templates/></li>
    </xsl:template>
    
    <!-- Note referents -->
    <xsl:template match="text:note">
        <a id="{@text:id}-ref" href="#{@text:id}" class="note-ref"><xsl:value-of select="text:note-citation"/></a>
    </xsl:template>
    
    <!-- Skip note text until end of document -->
    <xsl:template match="text:note-body"/>
    
    <!-- Notes -->
    <xsl:template name="Notes">
        <xsl:for-each select="//text:note/text:note-body">
            <xsl:apply-templates/>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Paragraphs -->
    <xsl:template match="text:p">
        <!-- Ignore empty paragraph tags -->
        <xsl:if test="string-length(.)>0">
            <xsl:choose>
                <!-- Don't put paragraph tags inside tables -->
                <xsl:when test="ancestor::table:table-cell">
                    <xsl:apply-templates/>
                </xsl:when>
                <!-- Or inside lists -->
                <xsl:when test="ancestor::text:list-item">
                    <xsl:apply-templates/>
                </xsl:when>
                <!-- Indicate notes with class -->
                <xsl:when test="ancestor::text:note-body">
                    <p class="note">
                        <a id="{ancestor::text:note/@text:id}" href="#{ancestor::text:note/@text:id}-ref">^</a><xsl:text> </xsl:text><xsl:value-of select="ancestor::text:note/text:note-citation"/><xsl:text> </xsl:text><xsl:apply-templates/>
                    </p>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="para-style" select="@text:style-name"/>
                    <xsl:variable name="para-style-def" select="/office:document-content/office:automatic-styles
                        /style:style[@style:name=$para-style]"/>
                    <xsl:variable name="margin-size" select="number(substring($para-style-def
                        /style:paragraph-properties/@fo:margin-left, 1, 1))"/>
                    <xsl:choose>
                        <!-- Indented paragraphs are blockquotes -->
                        <xsl:when test="$margin-size > 0">
                            <blockquote><p><xsl:apply-templates/></p></blockquote>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- Otherwise it's a plain old paragraph -->
                            <p><xsl:apply-templates/></p>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>        
        </xsl:if>
    </xsl:template>
    
    <!-- Spaces: have to put them in to avoid occasional tab weirdness such as <em/> -->
    <xsl:template match="text:s">
        <xsl:call-template name="make-space">
            <xsl:with-param name="count" select="@text:c"/><!-- gives the # of spaces -->
        </xsl:call-template>
    </xsl:template>
    
    <!-- Recursive calls are the only way to loop a specified number of times. Thanks Michael Kay! -->
    <xsl:template name="make-space">
        <xsl:param name="count"/>
        <xsl:if test="$count > 0">
            <xsl:text> </xsl:text>
            <xsl:call-template name="make-space">
                <xsl:with-param name="count" select="$count - 1"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <!-- Spans -->
    <xsl:template match="text:span">
        <xsl:variable name="current-span" select="@text:style-name"/>
        <xsl:variable name="matching-style" 
            select="//office:automatic-styles/style:style[@style:name=$current-span]"/>
        <xsl:choose>
            <!-- Output em tags when style applies italics -->
            <xsl:when test="$matching-style/style:text-properties/@fo:font-style='italic'">
                <em><xsl:apply-templates/></em>
            </xsl:when>
            <!-- Output strong tags when style applies bolding -->
            <xsl:when test="$matching-style/style:text-properties/@fo:font-weight='bold'">
                <strong><xsl:apply-templates/></strong>
            </xsl:when>
            <!-- All other span tags are useless -->
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Tables -->
    <xsl:template match="table:table">
        <table>
            <xsl:apply-templates/>
        </table>
    </xsl:template>
    
    <xsl:template match="table:table-column"/>
    
    <xsl:template match="table:table-row">
        <tr>
            <xsl:apply-templates/>
        </tr>
    </xsl:template>
    
    <xsl:template match="table:table-cell">
        <td><xsl:apply-templates/></td>
    </xsl:template>
    
</xsl:stylesheet>