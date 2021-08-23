releng.svg: releng.dot

%.svg: %.dot
	dot -Tsvg $< -o  $@

clean:
	rm -fv *.svg
