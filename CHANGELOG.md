# Changelog

## [2.3.0](https://github.com/stordco/buffy/compare/v2.2.0...v2.3.0) (2025-04-16)


### Features

* Add telemetry metric for process memory usage ([#43](https://github.com/stordco/buffy/issues/43)) ([b0fdb25](https://github.com/stordco/buffy/commit/b0fdb25f20b301f0dc96f9bbf0e63d5da5d7c486))
* Allow dynamic loop and throttle args ([#44](https://github.com/stordco/buffy/issues/44)) ([d065295](https://github.com/stordco/buffy/commit/d06529577889effbb7320d683b8952e510de88a0))


### Miscellaneous

* Create CODEOWNERS ([#48](https://github.com/stordco/buffy/issues/48)) ([b2b7920](https://github.com/stordco/buffy/commit/b2b792006f85838fa4f32c0a5b21fa8eaaf8f34e))
* Sync files with stordco/common-config-elixir ([#40](https://github.com/stordco/buffy/issues/40)) ([1409ddc](https://github.com/stordco/buffy/commit/1409ddc2394e1bf34f850fb7cd67ba979fb1c66f))
* Sync files with stordco/common-config-elixir ([#45](https://github.com/stordco/buffy/issues/45)) ([2971294](https://github.com/stordco/buffy/commit/297129486dd1e815289590644d38b74b5f5ad6ec))
* Sync files with stordco/common-config-elixir ([#49](https://github.com/stordco/buffy/issues/49)) ([a468420](https://github.com/stordco/buffy/commit/a468420cce097af083b999376c7918a585a47205))
* Update moduledoc module example snippets ([#41](https://github.com/stordco/buffy/issues/41)) ([2c4c8dc](https://github.com/stordco/buffy/commit/2c4c8dc11b4678498f09b0e905cfd1c1428a21a3))

## [2.2.0](https://github.com/stordco/buffy/compare/v2.1.1...v2.2.0) (2024-03-13)


### Features

* SIGNAL-5811 add time interval bucket feature to ThrottleAndTimed and make loop_interval optional ([#39](https://github.com/stordco/buffy/issues/39)) ([3d48d04](https://github.com/stordco/buffy/commit/3d48d04a3b25ffb8209a79c65926c1f4a8f4debe))


### Miscellaneous

* Sync files with stordco/common-config-elixir ([#27](https://github.com/stordco/buffy/issues/27)) ([d7cffde](https://github.com/stordco/buffy/commit/d7cffdeb910491418afdd21ff8fa12e96bb00c94))
* Sync files with stordco/common-config-elixir ([#38](https://github.com/stordco/buffy/issues/38)) ([c127668](https://github.com/stordco/buffy/commit/c1276688bfe69481abd7b6559453a6653cbc99a6))

## [2.1.1](https://github.com/stordco/buffy/compare/v2.1.0...v2.1.1) (2023-12-18)


### Bug Fixes

* SIGNAL-5504 fix usage of option fields and typespec ([#32](https://github.com/stordco/buffy/issues/32)) ([fbb8fd2](https://github.com/stordco/buffy/commit/fbb8fd25b778846afd6e919100ca56b96b220aee))

## [2.1.0](https://github.com/stordco/buffy/compare/v2.0.1...v2.1.0) (2023-12-15)


### Features

* Add jitter option to throttle function ([#26](https://github.com/stordco/buffy/issues/26)) ([7991f91](https://github.com/stordco/buffy/commit/7991f91dc09e34d1478a999d771b1be3fd5a88b9))


### Bug Fixes

* Debounce should be throttle ([#30](https://github.com/stordco/buffy/issues/30)) ([c0cd187](https://github.com/stordco/buffy/commit/c0cd187af50e3fc60c47464d2cf9ecc62e26f086))


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
