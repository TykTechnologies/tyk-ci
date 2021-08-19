releng.png: callgraph.png legend.png
	convert $^ -append $@

%.png: %.dot
	dot -Tpng $< > $@
