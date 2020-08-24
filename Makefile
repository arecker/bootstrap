.PHONY: test clean

test:
	TESTING="1" ./bootstrap.sh
clean:
	rm -rf ./tmp
install:
	./bootstrap.sh
