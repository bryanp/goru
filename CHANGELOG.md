## [v0.5.0](https://github.com/bryanp/goru/releases/tag/v0.5.0)

*released on 2023-12-24*

  * `chg` [#26](https://github.com/bryanp/goru/pull/26) Bump core dependencies ([bryanp](https://github.com/bryanp))

## [v0.4.2](https://github.com/bryanp/goru/releases/tag/v0.4.2)

*released on 2023-09-17*

  * `fix` [#24](https://github.com/bryanp/goru/pull/24) Close the io object when the routine is finished ([bryanp](https://github.com/bryanp))
  * `fix` [#25](https://github.com/bryanp/goru/pull/25) Handle IOError in the scheduler and reactor ([bryanp](https://github.com/bryanp))

## [v0.4.1](https://github.com/bryanp/goru/releases/tag/v0.4.1)

*released on 2023-07-29*

  * `fix` [#23](https://github.com/bryanp/goru/pull/23) Handle `IOError` in io routines ([bryanp](https://github.com/bryanp))

## [v0.4.0](https://github.com/bryanp/goru/releases/tag/v0.4.0)

*released on 2023-07-16*

  * `add` [#22](https://github.com/bryanp/goru/pull/22) Add reactor as a reader to `Goru::Routine` ([bryanp](https://github.com/bryanp))
  * `add` [#21](https://github.com/bryanp/goru/pull/21) Improve statuses ([bryanp](https://github.com/bryanp))
  * `add` [#20](https://github.com/bryanp/goru/pull/20) Add observer pattern to routines ([bryanp](https://github.com/bryanp))
  * `add` [#19](https://github.com/bryanp/goru/pull/19) Add ability to pause and resume a routine ([bryanp](https://github.com/bryanp))
  * `chg` [#18](https://github.com/bryanp/goru/pull/18) Remove the unused `observer` writer from `Goru::Channel` ([bryanp](https://github.com/bryanp))

## [v0.3.0](https://github.com/bryanp/goru/releases/tag/v0.3.0)

*released on 2023-07-10*

  * `chg` [#16](https://github.com/bryanp/goru/pull/16) Improve control flow ([bryanp](https://github.com/bryanp))
  * `fix` [#17](https://github.com/bryanp/goru/pull/17) Handle `IOError` from closed selector ([bryanp](https://github.com/bryanp))
  * `chg` [#15](https://github.com/bryanp/goru/pull/15) Rename `default_scheduler_count` ([bryanp](https://github.com/bryanp))
  * `chg` [#14](https://github.com/bryanp/goru/pull/14) Improve cold start of scheduler ([bryanp](https://github.com/bryanp))
  * `chg` [#13](https://github.com/bryanp/goru/pull/13) Go back to selector-based reactor ([bryanp](https://github.com/bryanp))
  * `chg` [#12](https://github.com/bryanp/goru/pull/12) Refactor bridges (again) ([bryanp](https://github.com/bryanp))
  * `dep` [#11](https://github.com/bryanp/goru/pull/11) Change responsibilities of routine sleep behavior to be more clear ([bryanp](https://github.com/bryanp))
  * `chg` [#10](https://github.com/bryanp/goru/pull/10) Optimize how reactor status is set ([bryanp](https://github.com/bryanp))
  * `chg` [#9](https://github.com/bryanp/goru/pull/9) Refactor bridges ([bryanp](https://github.com/bryanp))
  * `chg` [#8](https://github.com/bryanp/goru/pull/8) Cleanup finished routines on next tick ([bryanp](https://github.com/bryanp))

## [v0.2.0](https://github.com/bryanp/goru/releases/tag/v0.2.0)

*released on 2023-05-01*

  * `fix` [#6](https://github.com/bryanp/goru/pull/6) Finish routines on error ([bryanp](https://github.com/bryanp))
  * `fix` [#5](https://github.com/bryanp/goru/pull/5) Correctly set channel status to `finished` when closed ([bryanp](https://github.com/bryanp))
  * `chg` [#4](https://github.com/bryanp/goru/pull/4) Only log when routines are in debug mode ([bryanp](https://github.com/bryanp))
  * `fix` [#3](https://github.com/bryanp/goru/pull/3) Update `Goru::Channel#full?` to always return a boolean ([bryanp](https://github.com/bryanp))
  * `dep` [#2](https://github.com/bryanp/goru/pull/2) Remove ability to reopen channels ([bryanp](https://github.com/bryanp))

## [v0.1.0](https://github.com/bryanp/goru/releases/tag/v0.1.0)

*released on 2023-03-29*

  * `add` [#1](https://github.com/bryanp/featuring) Initial implementation ([bryanp](https://github.com/bryanp))


