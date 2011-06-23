set input-folder="02-PROLOGUE -- Final"
java -cp c:\saxon\saxon9he.jar net.sf.saxon.Transform -t -s:%input-folder%/meta.xml -xsl:html-to-epub.xsl input-folder=%input-folder% output-folder="young-book" no-of-chs=9
