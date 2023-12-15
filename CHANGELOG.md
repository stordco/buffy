# Changelog

## [2.0.2](https://github.com/stordco/buffy/compare/v2.0.1...v2.0.2) (2023-12-15)


### Miscellaneous

* Sync files with stordco/common-config-elixir ([#23](https://github.com/stordco/buffy/issues/23)) ([68bdd18](https://github.com/stordco/buffy/commit/68bdd18cacd7fef8007aa59def429c5b43f3c16a))

## [2.0.1](https://github.com/stordco/buffy/compare/v2.0.0...v2.0.1) (2023-10-03)


### Bug Fixes

* Update callback to match spec ([#21](https://github.com/stordco/buffy/issues/21)) ([5902653](https://github.com/stordco/buffy/commit/59026530d3daf561e209d441b3b98dd1634b2aaa))

## [2.0.0](https://github.com/stordco/buffy/compare/v1.2.2...v2.0.0) (2023-10-02)


### ⚠ BREAKING CHANGES

* `Buffy.Throttle.throttle/1` will now return `:ok` instead of `{:ok, pid}`

### Bug Fixes

* Return :ok for already started throttle processes ([#20](https://github.com/stordco/buffy/issues/20)) ([07909be](https://github.com/stordco/buffy/commit/07909be0e65c3afb088b6d356862c597912ea157))


### Miscellaneous

* Remove old publish workflow ([#15](https://github.com/stordco/buffy/issues/15)) ([4b10fec](https://github.com/stordco/buffy/commit/4b10fec5cf76a4ff3e28a153bf91d126d203cfee))
* Sync files with stordco/common-config-elixir ([#18](https://github.com/stordco/buffy/issues/18)) ([bfe20fd](https://github.com/stordco/buffy/commit/bfe20fd470e7c70963e3770bf14f744f35843300))
* Sync files with stordco/common-config-elixir ([#19](https://github.com/stordco/buffy/issues/19)) ([7395018](https://github.com/stordco/buffy/commit/73950186902771e381165b253ab41c94730b8362))
* Update Hex Link in README.md ([#17](https://github.com/stordco/buffy/issues/17)) ([68927c6](https://github.com/stordco/buffy/commit/68927c6b8f42fa4e6a21c0323592c10bfeb7f8e2))

## [1.2.2](https://github.com/stordco/buffy/compare/v1.2.1...v1.2.2) (2023-09-26)


### Bug Fixes

* Do not double supervise throttle module ([#13](https://github.com/stordco/buffy/issues/13)) ([ce046ba](https://github.com/stordco/buffy/commit/ce046bab47f6a622aad586af59f9caf061c99e28))
* Ensure to always hash binary version of args ([#14](https://github.com/stordco/buffy/issues/14)) ([6216805](https://github.com/stordco/buffy/commit/6216805da569a90e42b2b40693934e3a3d7abbc9))


### Miscellaneous

* Sync files with stordco/common-config-elixir ([#10](https://github.com/stordco/buffy/issues/10)) ([930fabe](https://github.com/stordco/buffy/commit/930fabef4d0815cfe144893091537d3405a12629))
* Sync files with stordco/common-config-elixir ([#12](https://github.com/stordco/buffy/issues/12)) ([7d190da](https://github.com/stordco/buffy/commit/7d190da93eaaf2be765f0b6a31ff9c419f51a06e))

## [1.2.1](https://github.com/stordco/buffy/compare/v1.2.0...v1.2.1) (2023-08-24)


### Miscellaneous

* Make buffy public ([#8](https://github.com/stordco/buffy/issues/8)) ([d1eb14f](https://github.com/stordco/buffy/commit/d1eb14fde266b97cf2e84d65914d568e73d827b8))

## [1.2.0](https://github.com/stordco/buffy/compare/v1.1.0...v1.2.0) (2023-08-24)


### Features

* Add telemetry to the throttle module ([#7](https://github.com/stordco/buffy/issues/7)) ([74539d8](https://github.com/stordco/buffy/commit/74539d86ea41c531d4743ad57f614fd0f359679e))


### Miscellaneous

* Add MIT license ([#5](https://github.com/stordco/buffy/issues/5)) ([fc4306a](https://github.com/stordco/buffy/commit/fc4306afb90b301860f549afe8950bf96aff9f62))
* Sync files with stordco/common-config-elixir ([#3](https://github.com/stordco/buffy/issues/3)) ([d8bdce2](https://github.com/stordco/buffy/commit/d8bdce2a9114885c8993e45d5b80df8008dc84a4))
* Update README ([#6](https://github.com/stordco/buffy/issues/6)) ([a874e46](https://github.com/stordco/buffy/commit/a874e46bcb35fe6ed7244e6d831ec8d620fa35ad))

## [1.1.0](https://github.com/stordco/buffy/compare/v1.0.0...v1.1.0) (2023-07-13)


### Features

* Make types and logic flow more clear ([7c57e46](https://github.com/stordco/buffy/commit/7c57e46d12941bbc4b79a7b01f7e40f948cd8d13))
* Setup basic elixir repository ([785b3b8](https://github.com/stordco/buffy/commit/785b3b8b158668ecc40a3437d992abe500a1883d))
* Simplify first module usage ([b13c522](https://github.com/stordco/buffy/commit/b13c52230116abad7bb258317e4bf260f8706a6f))


### Bug Fixes

* Update release please version ([33aa3c3](https://github.com/stordco/buffy/commit/33aa3c34139fe0669ee53c12b1f5467df4359270))
* Update test stream data to only run 500 times ([5a423ad](https://github.com/stordco/buffy/commit/5a423ad3324c83809a4c1758bcbd300c4d56fd04))
* Update test timeout to account for large CI runs ([535c739](https://github.com/stordco/buffy/commit/535c7392df9b74c95ef448177f9106aeb85fdc25))


### Miscellaneous

* Remove credo debug file ([1f1419b](https://github.com/stordco/buffy/commit/1f1419b5eccbfdef46f10c6c421f34c9505e72e4))
* Rename debounce module to throttle ([73d0cf5](https://github.com/stordco/buffy/commit/73d0cf58ea24f6769af6db46d6f62929cc7ab1ae))
* Sync files with stordco/common-config-elixir ([#2](https://github.com/stordco/buffy/issues/2)) ([c6e4f34](https://github.com/stordco/buffy/commit/c6e4f3465475bd7bbe7571a76a963dd5c74dba3a))
* Update Buffy.Throttle moduledoc ([c906c43](https://github.com/stordco/buffy/commit/c906c43c1d783cb8175d11f47d21e961a647812a))
