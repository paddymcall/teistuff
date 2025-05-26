TEI_STYLESHEETS := $(realpath Stylesheets)
TEI_P5 := $(realpath TEI/P5)
TEIODD := $(TEI_P5)/p5.xml
TMPDIR = /tmp
DOCSDIR = $(TMPDIR)/tei-docs

help:
	@echo "Switch to environment with:"
	@echo "guix time-machine -C channels.scm -- shell -m manifest.scm --container"

channels.scm:
	guix describe -f channels > channels.scm

clean-channels:
	rm -f channels.scm

clean-docs:
	rm -rf $(DOCSDIR)

clean-TEI:
	cd $(TEI_P5) && make clean

clean-Stylesheets:
	cd $(TEI_STYLESHEETS) && make clean

clean: clean-docs
clean: clean-Stylesheets
clean: clean-TEI

$(TEI_P5)/p5.xml:
	cd $(TEI_P5) && \
	make clean && \
	make XSL="$(abspath $(TEI_STYLESHEETS))" -e p5.xml

tei-docs: $(TEI_P5)/p5.xml
	@echo "Producing docs in $(DOCSDIR)/$(basename $(notdir $(TEIODD)))/en/html"
	@echo "Patience ..."
	@mkdir -p $(DOCSDIR)/$(basename $(notdir $(TEIODD)))/en/html
	@sed 's|http://www.tei-c.org/release/xml/tei/stylesheet|$(abspath Stylesheets)|g' \
		$(TEI_P5)/Utilities/guidelines.xsl.model > \
		$(DOCSDIR)/guidelines.xsl
	@cp $(TEI_P5)/odd.css \
		$(TEI_P5)/guidelines.css \
		$(TEI_P5)/guidelines-print.css \
		$(DOCSDIR)/$(basename $(notdir $(TEIODD)))/en/html
	@java -jar $(TEI_STYLESHEETS)/lib/saxon10he.jar  \
		$(TEIODD) \
		-xsl:$(DOCSDIR)/guidelines.xsl \
		outputDir=$(DOCSDIR)/$(basename $(notdir $(TEIODD)))/en/html \
		lang=en \
		doclang=en \
		documenationLanguage=en \
		googleAnalytics='' \
		verbose=$(VERBOSE)
