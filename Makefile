.PHONY: build push test

build:
	docker build -t scaamanho/osm-tile-server .

push: build
	docker push scaamanho/osm-tile-server:latest

test: build
	docker volume create osm-data
	docker run --name osm_import -v osm-data:/var/lib/postgresql/10/main overv/osm-tile-server import
	docker container rm osm_import
	docker run --name osm -v osm-data:/var/lib/postgresql/10/main -p 80:80 -d overv/osm-tile-server run