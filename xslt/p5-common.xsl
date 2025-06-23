<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:cudl="http://cudl.lib.cam.ac.uk/xtf/" 
    xmlns:json="http://www.w3.org/2005/xpath-functions"
    xmlns:functx="http://www.functx.com"
    xmlns:mml="http://www.w3.org/1998/Math/MathML"
    xmlns:teix="http://www.tei-c.org/ns/Examples"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="#all">
    
    <xsl:output method="html" version="5" indent="no" encoding="UTF-8"/>
    
    <xsl:param name="input.dir" />
    <xsl:variable name="useMathJax" select="true()"/>
    <xsl:variable name="documentId" select="((/tei:teiCorpus|/tei:TEI)/@xml:id)[1]"/>
    
    <xsl:template match="tei:div[@xml:id='element-reference']">
        <xsl:variable name="element-reference" select="string-join((replace($input.dir,'/$',''),'element-reference.xml'),'/')"/>
        <xsl:if test="doc-available($element-reference)">
            <xsl:copy-of select="doc($element-reference)"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tei:text" mode="#all">
        <div id="tei">
            <xsl:attribute name="class" select="/tei:TEI/@type[.!='']"/>
            <xsl:apply-templates mode="#current"/>
        </div>
        <xsl:call-template name="endnote"/>
        <div id="notepanels"/>
    </xsl:template>
    
    <xsl:template match="tei:body" mode="#all">
        <div class="body">
            <xsl:apply-templates mode="#current"/>
            <xsl:if test="not($useMathJax)">
                <script type="text/x-mathjax-config">
                    <xsl:text>MathJax.Hub.Config({jax: ["input/MathML", "output/HTML-CSS"],extensions: ["mml2jax.js","MathMenu.js","MathZoom.js", "AssistiveMML.js"],});</xsl:text>
                </script>
                <script src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.2/MathJax.js"/>
            </xsl:if>
        </div>
    </xsl:template>
    
    <xsl:template match="tei:div[not(normalize-space()) and not(descendant::tei:gap)]|         tei:text//tei:p[not(normalize-space()) and not(descendant::tei:gap)]|         tei:head[not(normalize-space()) and not(descendant::tei:gap)]|         tei:hi[not(normalize-space()) and not(descendant::tei:gap)]|         tei:l[not(normalize-space()) and not(descendant::tei:gap)]|         tei:lg[not(normalize-space()) and not(descendant::tei:gap)]|         tei:unclear[not(normalize-space()) and not(descendant::tei:gap)]" mode="normalised modernised"/>
    
    <xsl:template match="tei:div" mode="#all">
        <div>
            <xsl:if test="@xml:id">
                <xsl:attribute name="id" select="@xml:id"/>
            </xsl:if>
            <xsl:variable name="dropCap-shim" select="cudl:ensure-dropCap-containers-cleared(.)"/>
            <xsl:call-template name="add_class">
                <xsl:with-param name="tokens" select="string-join((@rendition, @rend, $dropCap-shim), ' ')"/>
            </xsl:call-template>
            <xsl:apply-templates mode="#current"/>
        </div>
    </xsl:template>
    
    <xsl:function name="cudl:ensure-dropCap-containers-cleared" as="xs:string*">
        <xsl:param name="current-node"/>
        <xsl:value-of select="
                if ($current-node/preceding-sibling::*[descendant::tei:hi[contains(@rend, 'dropCap')]]) then
                    'dropCap-clear'
                else
                    ()"/>
    </xsl:function>

    <xsl:template match="tei:head" mode="#all">
        <xsl:variable name="level">
            <xsl:choose>
                <xsl:when test="matches($documentId, '^SITE\d+$')">
                    <xsl:value-of select="count(ancestor::tei:div) + 1"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="2"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="h{$level}">
            <xsl:if test="@xml:id">
                <xsl:attribute name="id" select="@xml:id"/>
            </xsl:if>
            <xsl:call-template name="add_class">
                <xsl:with-param name="tokens" select="string-join((@rendition, tokenize(@rend, '\s+')[not(starts-with(., 'indent'))][1]), ' ')"/>
            </xsl:call-template>
            <xsl:apply-templates mode="#current"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:ref" mode="#all">
        <xsl:element name="a">
            <xsl:variable name="mode" select="if(matches(@target,'^SITE\d+([#?].+?)*$')) then 'site' else ''"/>
            <xsl:attribute name="href" select="cudl:write_ref_target(@target, $mode)"/>
            <xsl:variable name="rend_details" as="item()">
                <xsl:call-template name="render_inline">
                    <xsl:with-param name="tokens" select="@rend"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:call-template name="add_class">
                <xsl:with-param name="tokens" select="$rend_details//@classes"/>
            </xsl:call-template>
            <xsl:apply-templates mode="#current"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:figure" priority="2" mode="#all">
        <xsl:variable name="elem-name" select="cudl:get_container_name(.,'')" as="xs:string"/>
        <xsl:element name="{$elem-name}">
            <xsl:if test="@xml:id">
                <xsl:attribute name="id" select="@xml:id"/>
            </xsl:if>
            <xsl:attribute name="class" select="string-join(('image',normalize-space(@rend))[.!=''],' ')"/>
            <img>
                <xsl:attribute name="src">
                    <xsl:text>/resources/images/texts/</xsl:text>
                    <xsl:value-of select="tei:graphic/@url"/>
                </xsl:attribute>
                <xsl:attribute name="alt" select="(normalize-space(.//tei:figDesc))[1]"/>
            </img>
            <xsl:apply-templates select="tei:figDesc" mode="#current"></xsl:apply-templates>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:figure" mode="#all">
        
    </xsl:template>
    
    <xsl:template match="tei:figDesc" mode="#all">
        <xsl:element name="{cudl:get_container_name(.,'')}">
            <xsl:attribute name="class" select="normalize-space(string-join((@rend,'figure_caption'),' '))"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:element>
    </xsl:template>
        
    <xsl:template match="tei:text//tei:note[@target]" mode="diplomatic normalised modernised proofing"/>

    <xsl:template match="tei:text//tei:name|tei:text//tei:placeName|tei:rs|tei:term" mode="modernised" priority="2">
        <span class="{local-name()}">
            <xsl:apply-templates mode="#current"/>
        </span>
    </xsl:template>
    
    <xsl:template match="tei:foreign" mode="modernised" priority="2">
        <!-- TODO: Italicise foreign text -->
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <xsl:template match="tei:foreign" mode="#all" priority="1">
        <xsl:variable name="xmllang_attr" select="lower-case(@xml:lang)"/>
        <xsl:variable name="language" as="xs:string*">
            <xsl:choose>
                <xsl:when test="$xmllang_attr = ('grc','gre')">
                    <xsl:text>greek</xsl:text>
                </xsl:when>
                <xsl:when test="$xmllang_attr = ('heb','hebrew')">
                    <xsl:text>hebrew</xsl:text>
                </xsl:when>
                <xsl:when test="$xmllang_attr = ('syr','syriac')">
                    <xsl:text>syriac</xsl:text>
                </xsl:when>
                <xsl:when test="$xmllang_attr = ('sam','samaritan')">
                    <xsl:text>samaritan</xsl:text>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="rend_details" as="item()">
            <xsl:call-template name="render_inline">
                <xsl:with-param name="tokens" select="(@rend, 'foreign', $language)[.!='']"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:element name="{string($rend_details//text())}">
            <xsl:if test="$rend_details//@classes !=''">
                <xsl:attribute name="class" select="$rend_details//@classes"/>
            </xsl:if>
            <xsl:if test="$xmllang_attr = ('heb','hebrew')">
                <xsl:attribute name="dir" select="'rtl'"/>
            </xsl:if>
            <xsl:apply-templates mode="#current"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:hi|tei:text//tei:name|tei:text//tei:placeName|tei:rs|tei:term" mode="#all" priority="1">
        <xsl:variable name="rend_details" as="item()">
            <xsl:call-template name="render_inline">
                <xsl:with-param name="tokens" select="(@rend, local-name()[not(.='hi')])"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:element name="{string($rend_details//text())}">
            <xsl:if test="$rend_details//@classes !=''">
                <xsl:attribute name="class" select="$rend_details//@classes"/>
            </xsl:if>
            <xsl:apply-templates mode="#current"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:l" mode="#all">
        <xsl:element name="{cudl:get_container_name(.,'')}">
            <xsl:call-template name="add_class">
                <xsl:with-param name="tokens" select="('line', @rendition, tokenize(@rend, '\s+')[1])"/>
            </xsl:call-template>
            <xsl:apply-templates mode="#current"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:lb[not(@break='yes')]" mode="#all"/>
    <xsl:template match="tei:lb[@break='yes']" mode="#all">
        <br/>
    </xsl:template>
    
    <xsl:template match="tei:lg" mode="#all">
        <xsl:element name="{cudl:get_container_name(.,'')}">
            <xsl:attribute name="class" select="string-join(('lg',normalize-space(@rend)),' ')"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:space[@dim='vertical']" mode="#all">
        <br/>
        <br/>
    </xsl:template>
    
    <xsl:template match="tei:space[@dim='horizontal']" mode="#all">
        <xsl:variable name="dimensions">
            <xsl:call-template name="print_dimensions">
                <xsl:with-param name="unit" select="@unit"/>
                <xsl:with-param name="extent" select="@extent"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="extent_text">
            <xsl:choose>
                <xsl:when test="normalize-space($dimensions)!='' and $dimensions != 'Unknown' and $dimensions != 'Unclear'">
                    <xsl:value-of select="$dimensions"/>
                    <xsl:text> space left blank.</xsl:text>
                </xsl:when>
                <xsl:when test="$dimensions = 'Unknown' or $dimensions = 'Unclear'">
                    <xsl:text>Space left blank.</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>Space left blank.</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <span class="hspac">
            <xsl:if test="normalize-space($extent_text)!=''">
                <xsl:attribute name="title">
                    <xsl:value-of select="$extent_text"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="string(number(@extent))=@extent">
                <xsl:choose>
                    <xsl:when test="contains(@extent, '?')">
                        <xsl:call-template name="loop">
                            <xsl:with-param name="max" select="number(substring-before(@extent, '?'))"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="loop">
                            <xsl:with-param name="max" select="number(@extent)"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </span>
    </xsl:template>

    <xsl:template match="tei:pb[@xml:id]" mode="#all" priority="2">
        <xsl:element name="{cudl:get_container_name(.,'')}">
            <xsl:attribute name="class" select="'page'"/>
            <xsl:attribute name="id">
                <xsl:value-of select="@xml:id"/>
            </xsl:attribute>
            <xsl:text> &lt;</xsl:text>
            <xsl:next-match/>
            <xsl:text>&gt; </xsl:text>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:pb" mode="#all" priority="1">
        <xsl:value-of select="@n"/>
    </xsl:template>

    <xsl:template match="tei:table" mode="#all">
        <xsl:element name="{cudl:get_container_name(.,local-name())}">
            <xsl:call-template name="add_class">
                <xsl:with-param name="tokens" select="(local-name(), @rendition, tokenize(@rend, '\s+')[1])"/>
            </xsl:call-template>
            <xsl:if test="@xml:id">
                <xsl:attribute name="id" select="@xml:id"/>
            </xsl:if>
            <xsl:if test="@rendition">
                <xsl:attribute name="class" select="@rendition"/>
            </xsl:if>
            <xsl:apply-templates mode="#current"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:row" mode="#all">
        <xsl:element name="{cudl:get_container_name(.,'tr')}">
            <xsl:call-template name="add_class">
                <xsl:with-param name="tokens" select="('tr', @rendition, tokenize(@rend, '\s+')[1])"/>
            </xsl:call-template>
            <xsl:apply-templates mode="#current"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:cell" mode="#all">
        <xsl:element name="{cudl:get_container_name(.,'td')}">
            <xsl:call-template name="add_class">
                <xsl:with-param name="tokens" select="('td', @rendition, tokenize(@rend, '\s+')[1])"/>
            </xsl:call-template>
            <xsl:if test="@cols">
                <xsl:attribute name="colspan" select="@cols"/>
            </xsl:if>
            <xsl:if test="@rows">
                <xsl:attribute name="rowspan" select="@rows"/>
            </xsl:if>
            <xsl:apply-templates mode="#current"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:seg[not(@type=('head','p'))]" mode="#all">
        <span>
            <xsl:if test="@rend">
                <xsl:attribute name="class" select="normalize-space(@rend)"/>
            </xsl:if>
            <xsl:apply-templates mode="#current"/>
        </span>
    </xsl:template>
    
    <xsl:template match="tei:seg[@type=('head','p')]" mode="#all">
        <span>
            <xsl:call-template name="add_class">
                <xsl:with-param name="tokens" select="('inline', @type, tokenize(normalize-space(@rend), '\s+'))"/>
            </xsl:call-template>
            <xsl:apply-templates mode="#current"/>
        </span>
    </xsl:template>
    
    <xsl:template match="tei:list" mode="#all">
        <xsl:element name="{cudl:get_container_name(.,'ul')}">
            <xsl:call-template name="add_class">
                <xsl:with-param name="tokens" select="('ul', @rendition, tokenize(@rend, '\s+')[1])"/>
            </xsl:call-template>
            <xsl:apply-templates mode="#current"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:item" mode="#all">
        <xsl:element name="{cudl:get_container_name(.,'li')}">
            <xsl:call-template name="add_class">
                <xsl:with-param name="tokens" select="('li', @rendition, tokenize(@rend, '\s+')[1])"/>
            </xsl:call-template>
            <xsl:apply-templates mode="#current"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:gap[@reason='editorial']" mode="#all">
        <xsl:variable name="extent_text">
            <xsl:variable name="dimensions">
                <xsl:call-template name="print_dimensions">
                    <xsl:with-param name="unit" select="@unit"/>
                    <xsl:with-param name="extent" select="@extent"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="normalize-space($dimensions)!=''">
                    <xsl:text> (Extent: </xsl:text>
                    <xsl:value-of select="$dimensions"/>
                    <xsl:text>)</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <div class="editorial">
            <span class="gap">
                <xsl:attribute name="title">
                    <xsl:text>The editor has omitted text from this transcription</xsl:text>
                    <xsl:value-of select="$extent_text"/>
                </xsl:attribute>
                <xsl:text>{text not transcribed}</xsl:text>
            </span>
        </div>
    </xsl:template>


    
    
    <xsl:template match="tei:text//tei:note[not(@target)]" mode="diplomatic modernised normalised proofing">
    <!-- This template write note indicators in the body text for notes without @target
         note@target indicators are written using the anchor template above.
         note indicators are not linked to notes via an <anchor element>.
         Should this facility be wanted, it will be necessary to construct the noteID, which
         is just: <xsl:text>n</xsl:text><xsl:value-of select="$noteNumber"/>
      -->
        <xsl:variable name="noteNumber">
            <xsl:choose>
                <xsl:when test="@type='editorial'">
                    <xsl:number format="1" count="//tei:text//tei:note[@type='editorial']" level="any"/>
                </xsl:when>
                <xsl:when test="@type='imageLink'">
                    <xsl:number format="1" count="//tei:text//tei:note[@type='imageLink']" level="any"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:number format="1" count="//tei:anchor[key('note-target',concat('#',@xml:id))]|//tei:text//tei:note[not(@target) and not(@type)]" level="any"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="noteId">
            <xsl:choose>
                <xsl:when test="@type='editorial'">
                    <xsl:text>ed</xsl:text>
                </xsl:when>
                <xsl:when test="@type='imageLink'">
                    <xsl:text>img</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>n</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:value-of select="$noteNumber"/>
        </xsl:variable>
        <xsl:variable name="noteIndicator">
            <xsl:if test="@type='editorial'">
                <xsl:text>Editorial Note </xsl:text>
            </xsl:if>
            <xsl:if test="@type='imageLink'">
                <xsl:text>Image </xsl:text>
            </xsl:if>
            <xsl:value-of select="$noteNumber"/>
        </xsl:variable>
        <xsl:variable name="noteRef">
            <xsl:value-of select="$noteId"/>
            <xsl:text>-ref</xsl:text>
        </xsl:variable>
        <xsl:call-template name="write_note_indicator">
            <xsl:with-param name="id" select="$noteRef"/>
            <xsl:with-param name="indicator" select="$noteIndicator"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="//tei:anchor[key('note-target',concat('#',@xml:id))]" mode="endnote">
            <xsl:choose>
                <xsl:when test="key('note-target',concat('#',@xml:id))">
                    <xsl:apply-templates select="key('note-target',concat('#',@xml:id))" mode="endnote"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="anchorId">
                        <xsl:value-of select="@xml:id"/>
                    </xsl:variable>
                    <xsl:variable name="noteNumber">
                        <xsl:number format="1" count="//tei:anchor[key('note-target',concat('#',@xml:id))]|//tei:text//tei:note[not(@target) and not(@type)]" level="any"/>
                    </xsl:variable>
                    <xsl:variable name="noteId">
                        <xsl:text>n</xsl:text>
                        <xsl:value-of select="$noteNumber"/>
                    </xsl:variable>
                <xsl:element name="div">
                    <xsl:attribute name="id">
                        <xsl:value-of select="$noteId"/>
                    </xsl:attribute>
                    <xsl:attribute name="class">
                        <xsl:text>note</xsl:text>
                    </xsl:attribute>
                    <xsl:element name="p">
                        <sup class="nnumber">
                            <xsl:text>[</xsl:text>
                            <xsl:value-of select="$noteNumber"/>
                            <xsl:text>]</xsl:text>
                        </sup>
                        <xsl:text> NOTE ANCHOR WITHOUT A NOTE</xsl:text>
                    </xsl:element>
                </xsl:element>
                </xsl:otherwise>
            </xsl:choose>
    </xsl:template>
    
    <xsl:template match="tei:div[@type='html']" priority="99" mode="#all">
        <xsl:apply-templates mode="ns-changes"/>
    </xsl:template>
    
    <xsl:template match="text()" mode="ns-changes">
        <xsl:copy-of select="."/>
    </xsl:template>
    
    <xsl:template match="*" mode="ns-changes">
        <xsl:element name="{local-name()}">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="ns-changes"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template name="write_related_texts">
        <xsl:param name="ptrs"/>
        <xsl:if test="$ptrs[@type = ('parent')]">
            <div id="part_of">
                <p>
                    <strong>
                        <xsl:text>This document is part of </xsl:text>
                        <xsl:apply-templates select="$ptrs[@type = 'parent']" mode="#current"/>
                    </strong>
                </p>
                    <xsl:for-each select="('previous_part','next_part')">
                        <xsl:variable name="ptr_type" select="."/>
                        <xsl:if test="$ptrs[@type = $ptr_type]">
                            <p>
                                <xsl:text>The </xsl:text>
                                <xsl:value-of select="replace(., '_', ' ')"/>
                                <xsl:text> of this document is </xsl:text>
                                <a href="/view/texts/normalised/{$ptrs[@type = $ptr_type]/@target}">
                                    <xsl:apply-templates select="$ptrs[@type = $ptr_type]" mode="#current"/>
                                </a>
                            </p>
                        </xsl:if>
                    </xsl:for-each>
                
            </div>
        </xsl:if>
        
        <xsl:for-each select="('is_version_of','is_response_to','is_follow_up_to', 'is_responded_by','is_followed_up_by')">
            <xsl:variable name="ptr_type" select="."/>
            <xsl:if test="$ptrs[@type = $ptr_type]">
                <xsl:call-template name="write_related_block">
                    <xsl:with-param name="ptr_elems" select="$ptrs[@type = $ptr_type]"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="write_related_block">
        <xsl:param name="ptr_elems"/>
        
        <xsl:variable name="attr_name">
            <xsl:choose>
                <xsl:when test="$ptr_elems[@type = ('is_version_of')]">
                    <xsl:text>versions</xsl:text>
                </xsl:when>
                <xsl:when test="$ptr_elems[matches(@type, 'response')]">
                    <xsl:text>responses</xsl:text>
                </xsl:when>
                <xsl:when test="$ptr_elems[matches(@type, 'follow')]">
                    <xsl:text>follows</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <div id="{$attr_name}">
            <p>
                <strong>
                    <xsl:choose>
                        <xsl:when test="$ptr_elems[@type = 'is_version_of']">
                            <xsl:text>This document is a version of:</xsl:text>
                        </xsl:when>
                        <xsl:when test="$ptr_elems[@type = 'is_response_to']">
                            <xsl:text>This document is a reply to:</xsl:text>
                        </xsl:when>
                        <xsl:when test="$ptr_elems[@type = 'is_responded_by']">
                            <xsl:text>Responses to this document:</xsl:text>
                        </xsl:when>
                        <xsl:when test="$ptr_elems[@type = 'is_follow_up_to']">
                            <xsl:text>This document is a follow up to:</xsl:text>
                        </xsl:when>
                        <xsl:when test="$ptr_elems[@type = 'is_followed_up_by']">
                            <xsl:text>Follow ups to this document:</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </strong>
            </p>
            
                <xsl:for-each select="$ptr_elems">
                    <p>
                        <a href="/view/texts/normalised/{@target}">
                            <xsl:apply-templates select="." mode="#current"/>
                        </a>
                    </p>
                </xsl:for-each>
            
        </div>
    </xsl:template>
    
    <xsl:template match="tei:fw" mode="#all"/>
    
    <xsl:template match="tei:item/tei:ref/tei:persName[tei:surname]/tei:roleName[normalize-space(string-join(following-sibling::node(),''))='']" mode="#all">
        <xsl:text> (</xsl:text>
        <xsl:apply-templates mode="#current"/>
        <xsl:text>)</xsl:text>
    </xsl:template>
    
    <!--<xsl:template match="*" mode="#all">
        <xsl:element name="BUBBA">
            <xsl:attribute name="name" select="local-name()"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:element>
    </xsl:template>-->
    
    <xsl:template match="tei:formula" mode="#all">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <xsl:template match="mml:math[not((mml:mi|mml:mo|mml:mn)[not(@*)] and count(*)=1)]" mode="#all">
        <xsl:copy copy-namespaces="no">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="mathML"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mml:math[(mml:mi|mml:mo|mml:mn)[not(@*)] and count(*)=1]" mode="#all">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <xsl:template match="node() |@*" mode="mathML">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates select="@*|node()" mode="mathML"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template name="re-mode-templates">
        <xsl:param name="viewMode"/>
        <xsl:choose>
            <xsl:when test="$viewMode = 'diplomatic'">
                <xsl:apply-templates mode="diplomatic"/>
            </xsl:when>
            <xsl:when test="$viewMode = 'modernised'">
                <xsl:apply-templates mode="modernised"/>
            </xsl:when>
            <xsl:when test="$viewMode = 'normalised'">
                <xsl:apply-templates mode="normalised"/>
            </xsl:when>
            <xsl:when test="$viewMode = 'proofing'">
                <xsl:apply-templates mode="proofing"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="normalised"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="tei:val|tei:ident" mode="#all">
        <span class="{local-name()}">
            <xsl:apply-templates mode="#current"/>
        </span>
    </xsl:template>
    
    <xsl:template match="tei:att" mode="#all">
        <span class="att">
            <xsl:text>@</xsl:text>
            <xsl:apply-templates mode="#current"/>
        </span>
    </xsl:template>
    
    <xsl:template match="tei:gi|tei:tag" mode="#all">
        <span>
            <xsl:attribute name="class" select="local-name()"/>
            <code class="language-markup">
                <xsl:text>&lt;</xsl:text>
                <xsl:apply-templates mode="#current"/>
                <xsl:text>&gt;</xsl:text>
            </code>
        </span>
    </xsl:template>
    
    <xsl:template match="tei:eg" mode="#all">
        <xsl:variable name="container_element" select="cudl:determine-output-element-name(.,'div')"/>
        
        <xsl:element name="{$container_element}">
            <xsl:attribute name="class">eg</xsl:attribute>
            <xsl:apply-templates mode="#current"/>
        </xsl:element>
    </xsl:template>
    
    <!-- Handling of <egXML> elements in the TEI example namespace. -->
    <xsl:template match="teix:egXML" mode="#all">
        <xsl:variable name="container_element" select="cudl:determine-output-element-name(.,'div')"/>
        
        <xsl:element name="{$container_element}">
            <xsl:attribute name="class">xmlCodeChunk</xsl:attribute>
            <code class="language-markup">
                <xsl:value-of select="replace(replace(.,'&amp;amp;','&amp;'),' xmlns=&quot;http://www.tei-c.org/ns/1.0&quot;','')" disable-output-escaping="no"/>
                <!-- To preserve indenting:
          <xsl:value-of select="replace(.,'&amp;amp;','&amp;')" disable-output-escaping="no"/>
          -->
            </code>
        </xsl:element>
    </xsl:template>
    
    <!--<xsl:template match="text()[parent::tei:*]|tei:persName/text()[normalize-space()][following-sibling::*]" mode="#all">
        <xsl:variable name="string" select="."/>
        
        <!-\-<xsl:variable name="cardo">[&#x2e2b;&#x292;&#x2108;&#x2125;&#x2114;&#xe270;&#xa770;&#xa76b;&#xa75b;&#xe8b3;&#xa757;&#x180;&#x1e9c;&#xa75d;&#xa75f;&#xa76d;&#xa76f;&#x204a;&#x119;&#x271d;&#x211e;&#x2720;&#x2641;&#x25b3;&#x260c;&#x260d;&#x2297;&#x260a;&#x260b;]</xsl:variable>-\->
        <xsl:variable name="junicode-shim" as="xs:string">[&#xe670;&#xe8bf;&#xe270;]</xsl:variable>
        <xsl:variable name="newton" as="xs:string">[&#x261e;&#x2020;&#x2016;&#xe704;&#xe70d;&#x2652;&#x2648;&#x264c;&#xe002;&#x2653;&#x264f;&#x2649;&#x264d;&#x264a;&#x264b;&#x264e;&#x2650;&#x2651;&#xe714;&#x263e;&#x263e;&#x2640;&#x2640;&#x263f;&#x2609;&#x2609;&#xe739;&#x2642;&#x2642;&#x2643;&#x2643;&#x2644;&#x2644;&#xe704;&#x26b9;&#x25a1;&#xe74e;]</xsl:variable>
        <xsl:variable name="greek" as="xs:string*">
            <xsl:choose>
                <xsl:when test="ancestor::tei:foreign[@xml:lang=('gre','grc')]"/>
                <xsl:otherwise>
                    <xsl:text>[\p{IsGreek}|\p{IsGreekExtended}]+((\s|\p{P})+[\p{IsGreek}|\p{IsGreekExtended}]+)*</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-\- NB: Is df needed? -\->
        <!-\-<xsl:variable name="df">&#x101;&#x7c;&#x111;&#x7c;&#x113;&#x7c;&#x12b;&#x7c;&#x6d;&#x304;&#x7c;&#x6e;&#x304;&#x7c;&#x14d;&#x7c;&#x16b;&#x7c;&#x77;&#x304;&#x7c;&#x233;</xsl:variable>-\->
        
        <xsl:analyze-string select="$string" regex="({string-join(($newton,$junicode-shim,$greek),'|')})">
            
            <xsl:matching-substring>
                <xsl:choose>
                    <xsl:when test="matches(.,$junicode-shim)">
                        <xsl:value-of select="replace(replace(replace(.,'&#xe670;','&#xA751;'),'&#xe8bf;','&#xE8BF;'),'&#xe270;','&#xA750;')"/>
                    </xsl:when>
                    <!-\-<xsl:when test="matches(.,$cardo)">
                        <span class="cardo">
                            <xsl:value-of select="."/>
                        </span>
                    </xsl:when>-\->
                    <xsl:when test="matches(.,$newton)">
                        <span class="ns">
                            <xsl:value-of select="."/>
                        </span>
                    </xsl:when>
                    <!-\-<xsl:when test="matches(.,$df)">
                        <span class="df">
                            <xsl:value-of select="."/>
                        </span>
                    </xsl:when>-\->
                    <xsl:when test="matches(.,$greek)">
                        <span class="greek">
                            <xsl:value-of select="."/>
                        </span>
                    </xsl:when>
                </xsl:choose>
            </xsl:matching-substring>
            
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
            
        </xsl:analyze-string>
    </xsl:template>-->
    
    <xsl:template match="node()[normalize-space(.)][following-sibling::node()[1][self::tei:hi[@rend='dropCap']]]" priority="9" mode="#all">
        <span class="dropcap-shim"><xsl:next-match/></span>
    </xsl:template>
    
    <!--<xsl:template match="*[tei:hi[@rend='dropCap'][preceding-sibling::node()[normalize-space(.)]]][not(tei:seg[@rend='dropcap-shim'])]" priority="9" mode="#all">
        <xsl:variable name="add_shim">
            <xsl:copy>
                <xsl:copy-of select="@* except @rend"/>
                <xsl:attribute name="rend" select="string-join((@rend,'dropCap-container'), ' ')"/>
                <seg rend="dropcap-shim" xmlns="http://www.tei-c.org/ns/1.0">
                    <xsl:copy-of select="./tei:hi[@rend = 'dropCap']/preceding-sibling::node()[normalize-space(.)]"/>
                </seg>
                <xsl:copy-of select="./tei:hi[@rend = 'dropCap']/preceding-sibling::node()[normalize-space(.)]/following-sibling::node()"/>
            </xsl:copy>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="$viewMode='diplomatic'">
                <xsl:apply-templates select="$add_shim" mode="diplomatic"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$add_shim" mode="normalised"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>-->
    
    <xsl:template match="*[tei:seg[@rend='dropcap-shim']]" priority="10" mode="diplomatic normalised">
        <xsl:next-match/>
    </xsl:template>
    
    
    
    <xsl:function name="cudl:determine-output-element-name">
        <xsl:param name="node"/>
        <xsl:param name="default"/>
        
        <xsl:choose>
            <xsl:when test="$node[ancestor::tei:p | ancestor::tei:l | ancestor::tei:item]">
                <xsl:text>span</xsl:text>
            </xsl:when>
            <xsl:when test="$node[not(ancestor::tei:p | ancestor::tei:l | ancestor::tei:item)]">
                <xsl:text>div</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$default"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="cudl:write_ref_target" as="xs:string">
        <xsl:param name="target"/>
        <xsl:param name="mode"/>
        
        <xsl:value-of select="$target"/>
    </xsl:function>
    
    <xsl:function name="cudl:get_container_name">
        <xsl:param name="node"/>
        <xsl:param name="default_block_name"/>
        
        <xsl:variable name="is_inline" select="boolean($node[ancestor::tei:p or ancestor::tei:head or ancestor::tei:l])"/>
        <xsl:choose>
            <xsl:when test="$is_inline = true()">
                <xsl:text>span</xsl:text>
            </xsl:when>
            <xsl:when test="$is_inline = false()">
                <xsl:value-of select="(($default_block_name,'div')[not(.='')])[1]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>span</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="cudl:simple_pluralise" as="xs:string">
        <xsl:param name="string"/>
        <xsl:param name="count"/>
        
        <xsl:variable name="suffix">
            <xsl:choose>
                <xsl:when test="$count &gt; 1">
                    <xsl:text>s</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="concat($string,$suffix)"/>
    </xsl:function>
    
    <xsl:function name="cudl:capitalize-first" as="xs:string">
        <xsl:param name="arg"/>
        <xsl:sequence select="concat(upper-case(substring($arg,1,1)),substring($arg,2))"/>
    </xsl:function>
    
    <xsl:function name="functx:sort" as="item()*">
        <xsl:param name="seq" as="item()*"/>
        
        <xsl:for-each select="$seq">
            <xsl:sort select="."/>
            <xsl:copy-of select="."/>
        </xsl:for-each>
        
    </xsl:function>
    
        <xsl:template name="print_dimensions">
            <xsl:param name="unit"/>
            <xsl:param name="extent"/>
            <xsl:variable name="var_num">
                <xsl:choose>
                    <xsl:when test="contains(@extent, '?')">
                        <xsl:value-of select="substring-before(@extent, '?')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@extent"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="parsedUnit">
                <xsl:if test="string(number(@extent))= @extent">
                    <xsl:call-template name="parseUnit">
                        <xsl:with-param name="unit" select="@unit"/>
                        <xsl:with-param name="extent" select="@extent"/>
                    </xsl:call-template>
                </xsl:if>
            </xsl:variable>
            <xsl:variable name="dimensions_text">
                <xsl:choose>
                    <xsl:when test="string(number($var_num))= $var_num and $parsedUnit !=''">
                        <xsl:value-of select="@extent"/>
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="$parsedUnit"/>
                    </xsl:when>
                    <xsl:when test="@extent = 'unknown' or @extent = 'unclear'">
                        <xsl:text>Unclear</xsl:text>
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>
            <xsl:value-of select="$dimensions_text"/>
        </xsl:template>
        
        <xsl:template name="parseUnit">
            <xsl:param name="unit"/>
            <xsl:param name="extent"/>
            <xsl:variable name="unit_tmp">
                <xsl:choose>
                    <xsl:when test="$unit = 'char' or $unit = 'character' or $unit = 'chars' or $unit = 'characters'">
                        <xsl:text>character</xsl:text>
                    </xsl:when>
                    <xsl:when test="$unit = 'word' or $unit = 'words'">
                        <xsl:text>word</xsl:text>
                    </xsl:when>
                    <xsl:when test="$unit = 'line' or $unit = 'lines'">
                        <xsl:text>line</xsl:text>
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>
            <xsl:value-of select="cudl:simple_pluralise($unit_tmp,$extent)"/>
        </xsl:template>
        
        <xsl:template name="add_class" as="item()*">
            <xsl:param name="tokens"/>
            <xsl:param name="default"/>
            
            <xsl:variable name="tk" select="tokenize(normalize-space(string-join($tokens,' ')),'\s+')"/>
            
            <xsl:variable name="distinct_tokens">
                <xsl:choose>
                    <xsl:when test="count(($tk)[not(.='')])&gt;0">
                        <xsl:copy-of select="$tk"/>
                    </xsl:when>
                    <xsl:when test="$default[not(.='')]">
                        <xsl:copy-of select="$default"/>
                    </xsl:when>
                    <xsl:otherwise/>
                </xsl:choose>
            </xsl:variable>
            <xsl:if test="$distinct_tokens[not(.='')]">
                <xsl:attribute name="class">
                    <xsl:value-of select="string-join(functx:sort($distinct_tokens),' ')"/>
                </xsl:attribute>
            </xsl:if>
        </xsl:template>
        
        <xsl:template name="render_inline">
            <xsl:param name="tokens"/>
            
            <xsl:variable name="tokenized_items" select="tokenize(normalize-space(string-join($tokens,' ')),'\s+')"/>
            <xsl:variable name="token_map">
                <list>
                    <item n="bold">strong</item>
                    <item n="doubleUnderline">em</item>
                    <item n="italic">em</item>
                    <item n="subscript" suppressClass="yes">sub</item>
                    <item n="superscript" suppressClass="yes">sup</item>
                    <item n="underline">em</item>
                </list>
            </xsl:variable>
            
            <xsl:variable name="results" as="item()">
                <item classes="{$tokenized_items[not(.=$token_map//*:item[@suppressClass='yes']/@n)]}">
                    <xsl:value-of select="($token_map//*:item[@n=$tokenized_items[1]], 'span')[.!=''][1]"/>
                </item>
            </xsl:variable>
            
            <xsl:copy-of select="$results"/>
        </xsl:template>
    
    <xsl:template name="loop">
        <xsl:param name="max"/>
        <xsl:if test="$max &gt; 0">
            <xsl:text> </xsl:text>
            <xsl:call-template name="loop">
                <xsl:with-param name="max" select="$max - 1"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="endnote">
        <xsl:param name="mode"/>
        
        <div id="endnotes">
            <xsl:apply-templates select="//tei:anchor[key('note-target',concat('#',@xml:id))]|//tei:text//tei:note[not(@target)]" mode="endnote"/>
        </div>
    </xsl:template>
    
    <xsl:template name="write_note_indicator">
        <xsl:param name="id"/>
        <xsl:param name="indicator"/>
        <sup class="note">
            <xsl:attribute name="id">
                <xsl:value-of select="$id"/>
            </xsl:attribute>
            <xsl:text>[</xsl:text>
            <xsl:value-of select="$indicator"/>
            <xsl:text>]</xsl:text>
        </sup>
    </xsl:template>
</xsl:stylesheet>