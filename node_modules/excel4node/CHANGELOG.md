# Changelog

## [1.8.2](https://github.com/advisr-io/excel4node/compare/v1.8.1...v1.8.2) (2023-05-02)

### Bug Fixes:

* Use more standard representation of boolean values in cells, thanks [pineapplemachine](https://github.com/pineapplemachine) ([#62](https://github.com/advisr-io/excel4node/pull/62))

### Enhancements

* upgrade dependencies ([#60](https://github.com/advisr-io/excel4node/pull/60)) ([#61](https://github.com/advisr-io/excel4node/pull/61))


## [1.8.1](https://github.com/advisr-io/excel4node/compare/v1.8.0...v1.8.1) (2023-03-31)

### Bug Fixes:

* fixing a date issue about one millisecond before midnight, thanks [krisanselmo](https://github.com/krisanselmo) ([#54](https://github.com/advisr-io/excel4node/pull/54))

### Enhancements

* upgrade dependencies ([#26](https://github.com/advisr-io/excel4node/pull/26)) ([#30](https://github.com/advisr-io/excel4node/pull/30)) ([#41](https://github.com/advisr-io/excel4node/pull/41)) ([#42](https://github.com/advisr-io/excel4node/pull/42)) ([#50](https://github.com/advisr-io/excel4node/pull/50)) ([#51](https://github.com/advisr-io/excel4node/pull/51)) ([#52](https://github.com/advisr-io/excel4node/pull/52)) ([#55](https://github.com/advisr-io/excel4node/pull/55)) ([#56](https://github.com/advisr-io/excel4node/pull/56)) ([#57](https://github.com/advisr-io/excel4node/pull/57))


### Default branch update:
We've migrated the default branch from master to main


## [1.8.0](https://github.com/advisr-io/excel4node/compare/v1.7.2...v1.8.0) (2022-07-21)

### New Repo & Maintainer:
Huge thanks to [natergj](https://github.com/natergj) for his work on this library. Due to life circumstances he is no longer able to maintain this library and he has passed the torch over to us at [Advisr](https://github.com/advisr-io) to continue. We will be continuing development of this library on our fork [https://github.com/advisr-io/excel4node](https://github.com/advisr-io/excel4node) and the original repo will be deprecated. New versions will still be released to the original NPM package [https://www.npmjs.com/package/excel4node](https://www.npmjs.com/package/excel4node).

This release is meant to bring the package up to date with its various dependencies to address security vulnerabilities found since the last release three years ago. Additionally a few pull requests from the original repo have been merged to address a few outstanding bug/feature requests. Thanks to [Arthur Blake](https://github.com/arthurblake-AngelOak) for identifying the pull requests to transfer over from the original repo.

### Bug Fixes:

* wb.Worksheep is not a function, thanks [huihui0606](https://github.com/huihui0606) ([#1](https://github.com/advisr-io/excel4node/pull/1))
* error handling for cell row/col smaller than 1 [original issue](https://github.com/natergj/excel4node/issues/139), thanks [firlus](https://github.com/firlus) ([#2](https://github.com/advisr-io/excel4node/pull/2))
* add default cell style definition [original pr](https://github.com/natergj/excel4node/pull/353), thanks [artiz](https://github.com/artiz ) ([#3](https://github.com/advisr-io/excel4node/pull/3))
* fix getExceTS daylight savings bug [original pr](https://github.com/natergj/excel4node/pull/333), thanks [finnshort](https://github.com/finnshort ) ([#4](https://github.com/advisr-io/excel4node/pull/4))
* fix readingOrder [original issue](https://github.com/natergj/excel4node/issues/327), thanks [atlanteh](https://github.com/atlanteh ) ([#5](https://github.com/advisr-io/excel4node/pull/5))

### Enhancements:

* upgrade dependencies ([92541fa](https://github.com/advisr-io/excel4node/commit/92541fa6c2c2268b9175341a42cf50d38a75c34b)) ([11dd63d](https://github.com/advisr-io/excel4node/commit/11dd63dce0f7ae508190e88c814c04430778dab5)) ([#7](https://github.com/advisr-io/excel4node/pull/7)) ([#24](https://github.com/advisr-io/excel4node/pull/24))
* allow access to set picture rId manually to reduce filesize for reused images [original issue](https://github.com/natergj/excel4node/issues/302), thanks [Newbie012](https://github.com/Newbie012) ([#6](https://github.com/advisr-io/excel4node/pull/6)) ([#21](https://github.com/advisr-io/excel4node/pull/21))

### Breaking Changes:

* Node versions less than v14 (current maintenance LTS) are no longer supported.
  * Please upgrade to the latest LTS release of Node (we recommend either v14 or v16).
  * When bringing the library dependencies up to date we were forced to increase the minimum node version requirement to their level


## [1.7.2](https://github.com/advisr-io/excel4node/compare/v1.7.1...v1.7.2) (2019-04-28)

### Bug Fixes:

* fix issue when comment drawing changing after save ([#283](https://github.com/natergj/excel4node/issues/283))


## [1.7.1](https://github.com/advisr-io/excel4node/compare/v1.7.0...v1.7.1) (2019-03-25)

### Bug Fixes:

* fix issue where multiple complex strings could not be used ([#269](https://github.com/natergj/excel4node/issues/269))
* fix README typo ([#264](https://github.com/natergj/excel4node/pull/264))
* fix license format ([#272](https://github.com/natergj/excel4node/pull/272))
* fix TypeError: deepmerge is not a function ([#258](https://github.com/natergj/excel4node/issues/258))


## [1.7.0](https://github.com/advisr-io/excel4node/compare/v1.6.0...v1.7.0) (2018-10-07)

### Bug Fixes:

* fix issue with certain emoji characters ([#238](https://github.com/natergj/excel4node/issues/238))
* fix issue with workbook validation using .Net validation library provided by Microsoft ([#240](https://github.com/natergj/excel4node/pull/240))
* fix issue where first tab will still be shown even if it is hidden ([#236](https://github.com/natergj/excel4node/issues/236))

### Enhancements:

* add basic cell comment functionality ([#243](https://github.com/natergj/excel4node/pull/243))


## [1.6.0](https://github.com/advisr-io/excel4node/compare/v1.5.1...v1.6.0) (2018-09-16)

### Bug Fixes:

* fix issue where emoji were not being added to worksheets ([#232](https://github.com/natergj/excel4node/pull/232))

### Enhancements:

* add ability to set Print Area for worksheets ([#194](https://github.com/natergj/excel4node/issues/194))
* add ability to set Page Breaks for worksheets ([#233](https://github.com/natergj/excel4node/issues/233))


## [1.5.1](https://github.com/advisr-io/excel4node/compare/v1.5.0...v1.5.1) (2018-09-09)

### Bug Fixes:

* fix issue where library crashed when null or undefined value was sent to cell string method ([#218](https://github.com/natergj/excel4node/issues/218))
* fix issue where default font would not be applied to dates when opening workbook in LibreOffice ([#226](https://github.com/natergj/excel4node/issues/226))
* fixerror when attempting to bundle application with excel4node as dependency ([#225](https://github.com/natergj/excel4node/pull/225))

### Enhancements:

* reduces library size by only installed specific lodash functions ([#230](https://github.com/natergj/excel4node/pull/230))


## [1.5.0](https://github.com/advisr-io/excel4node/compare/v1.4.0...v1.5.0) (2018-07-22)

### Bug Fixes:

* fix error will be thrown if no Worksheet is specified prior to attempting to write a Workbook ([#156](https://github.com/natergj/excel4node/issues/156))

### Enhancements:

* merge ([#211](https://github.com/natergj/excel4node/pull/211)) & ([#212](https://github.com/natergj/excel4node/pull/212))
  * remove default logger dependency in favor of much smaller simple logger (reduces library dependencies and size)
  * add ability specify custom logger


## [1.4.0](https://github.com/advisr-io/excel4node/compare/v1.3.6...v1.4.0) (2018-07-07)

### Bug Fixes:

* fix issue where unicode filenames could not be used with HTTP Response write handler ([#196](https://github.com/natergj/excel4node/issues/196))

### Enhancements:

* add ability to hide worksheets ([#201](https://github.com/natergj/excel4node/pull/201))


## [1.3.6](https://github.com/advisr-io/excel4node/compare/v1.3.5...v1.3.6) (2018-03-21)

### Bug Fixes:

* fix to allow column widths to be set as floats ([#182](https://github.com/natergj/excel4node/issues/182))
* fix to properly handle setting row autofilter with no arguments ([#184](https://github.com/natergj/excel4node/issues/184))
* fix typo in documentation ([#181](https://github.com/natergj/excel4node/pull/181))


## [1.3.5](https://github.com/advisr-io/excel4node/compare/v1.3.4...v1.3.5) (2018-02-03)

### Bug Fixes:

* fix to properly handle unicode and emoji ([#141](https://github.com/natergj/excel4node/pull/141))
* fix to correct issue with row spans causing errors when opening workbooks with a large number of lines ([#172](https://github.com/natergj/excel4node/pull/172))


## [1.3.4](https://github.com/advisr-io/excel4node/compare/v1.3.2...v1.3.4) (2018-01-24)

### Bug Fixes:

* resolved issue where if multiple conditional formatting rules were specified for a single sheet, only the first rule would apply
* resolve issue adding multiple dataValidations that did not include a formula to a single worksheet ([#164](https://github.com/natergj/excel4node/issues/164))

### Enhancements:

* improve performance with shared strings ([#165](https://github.com/natergj/excel4node/pull/165))
        

## [1.3.2](https://github.com/advisr-io/excel4node/compare/v1.3.1...v1.3.2) (2017-11-30)

### Bug Fixes:

* fix issue after 1.3.0 re-introduced issue #84 ([#152](https://github.com/natergj/excel4node/issues/152))
        

## [1.3.1](https://github.com/advisr-io/excel4node/compare/v1.3.0...v1.3.1) (2017-11-25)

### Bug Fixes:

* fix for uncatchable thrown errors ([#148](https://github.com/natergj/excel4node/issues/148))
* fix for incorrectly generated links ([#106](https://github.com/natergj/excel4node/issues/106))
* fix for missing fills in conditional formatting ([#147](https://github.com/natergj/excel4node/issues/147))


## [1.3.0](https://github.com/advisr-io/excel4node/compare/v1.2.1...v1.3.0) (2017-11-12)

### Enhancements:

* add option to hide view lines ([#117](https://github.com/natergj/excel4node/pull/117))
* add code coverage checking ([#109](https://github.com/natergj/excel4node/pull/109))
* allow for image from buffer support ([#138](https://github.com/natergj/excel4node/pull/138))
* add options for workbook view ([1c4a7bf](https://github.com/natergj/excel4node/commit/1c4a7bf990160b47ad8e0f49c00a536dca7ab672))
* fix issue where ony first data validation per sheet would take effect ([ff629a2](https://github.com/natergj/excel4node/commit/ff629a225335dc784933c06aabd20ddca5fcdbef))

### Bug fixes:

* fix issue when adding 2nd image of same extension ([#99](https://github.com/natergj/excel4node/pull/99))
* fix deprecated lodash function warning ([#115](https://github.com/natergj/excel4node/pull/115))
* fix link in README ([#125](https://github.com/natergj/excel4node/pull/125))
* fix to remove babel-register runtime dependency ([#119](https://github.com/natergj/excel4node/pull/119))
* fix issue with summaryBelow and summaryRight ([#132](https://github.com/natergj/excel4node/pull/132))
* use latest version of mime module ([78180e6](https://github.com/natergj/excel4node/commit/78180e6a0a1f0a50e43b588902da37fdee5be7bb))
* update dependencies ([b96f01a](https://github.com/natergj/excel4node/commit/b96f01a2923e2823377f10c28a97a3fe2c5c5f50))
* fixes date translations to match published spec ([b3fcb8a](https://github.com/natergj/excel4node/commit/b3fcb8aa6674c644838f81a9170f2b6d975803b6))
* fix issue where workbook would always open as smallest possible window size ([1c4a7bf](https://github.com/natergj/excel4node/commit/1c4a7bf990160b47ad8e0f49c00a536dca7ab672))


## 1.2.1

* Fix Workbook#createStyle creating duplicates and slow performance [#100]


## 1.2.0

* merged https://github.com/natergj/excel4node/pull/91 from miguelmota to expose writeToBuffer method allowing excel zip buffer to be piped to other streams
* added documentation to README
* fixed some errors in README


## 1.1.2

* dependency cleanup
* updated to version 3.x.x of jszip


## 1.1.1

* Improved effeciency when writing Workbooks to help address Issue #83. Tested with 50 columns and 30,000 rows.


## 1.1.0

* Fixed issue where defaultRowHeight set in Workbook opts was not being properly handled.


## 1.0.9

* Fixed issue #90 which would result in a type error being thrown if a dataValidation errorTitle was set and errorStyle was not


## 1.0.8

* Removed debug line that had been missed prior to publish


## 1.0.7

* Fixed issue #89 which would result in dates showing a 1 hour offset if date was in daylight savings time


## 1.0.6

* Fixed issue #87 which would result in non-logical behaviour of showDropDown="true" for dataValidations
* Fixed issue #88 which would result in fonts set as default for workbook not having all of their attributes respected for cells that had a style assigned to them that only included a subset of the font attributes.


## 1.0.5  

* Fixed issue #84 which would result in Office 2013 on Windows crashing when attempting to print a workbook.


## 1.0.4

* Fixed issue #82 which would result in call stack size being exceeded when workbook was being written


## 1.0.3

* Fixed issue where border.outline property was not applying border only to cells on out the outside of the cell block
* Fixed issue where an excessive number of style xfs may have been added to styles.xml file


## 1.0.2

* Fixed some inaccuracies in the README.md file


## 1.0.1

* Removed a missed remnant of old code that wasn't removed during the merge
* Excluded development tests folder from npm published code


## 1.0.0 

* Complete rewrite of library in ES2015
* This is a breaking change for API.  Library is much more javascripty


## 0.5.1

* Merged pull request 76 from https://github.com/bhuvanaurora to fix issue that would arise if you tried to add an emoji to an excel document


## 0.5.0

* Merged pull request 74 from https://github.com/pindinz to add support for specifying specific paper size


## 0.4.1

* Fixed issue causing problems when trying to bundle


## 0.4.0

* Merged pull requests 67, 59, 60, 64, 66, 67 from https://github.com/dgofman
* Added ability to create cells with complex multiple formatting within a single cell
* Added ability to include headers and footers in worksheets
* Added ability to repeat specific rows or columns on every printed page (https://support.office.com/en-us/article/Repeat-specific-rows-or-columns-on-every-printed-page-0d6dac43-7ee7-4f34-8b08-ffcc8b022409)
* removed allowInterrupt options. It was causing issues
* Added ability to set a default font across workbook
* Fixed issues with images
* Fixed issue with print orientation and scaling


## 0.3.1

* Merged https://github.com/natergj/excel4node/pull/53 from https://github.com/bugeats.
* More tests added
* Added support for limited number of conditional formatting rules


## 0.3.0

* Merged https://github.com/natergj/excel4node/pull/52 from https://github.com/bugeats. Code cleanup refactor, added .eslintrc.js file and tests.


## 0.2.23

* Merged https://github.com/natergj/excel4node/pull/50 from https://github.com/dmnorc to fix bug with setting size of font through Cell.Format methods.


## 0.2.22

* Added the ability to reference Cells in another sheet in validations
* Merged pull request https://github.com/natergj/excel4node/pull/48 from https://github.com/dteunkenstt to add ability to set Cells with Boolean values


## 0.2.21

* Fixed issue where files with spaces in their names were not correctly downloading in Firefox.


## 0.2.20

* Added the ability to add "Protection" to Workbooks and Worksheets
* Fixed issue where Row.Filter() would not filter the correct row if workbook opened in LibreOffice or uploaded to GoogleSheets
* Added the .Border() function to individual cell ranges rather than requiring borders to be defined within a Style
* Added opts.allowInterrupt which will use an asynchronous forEach function in order not to block other operations if reports are being generated on the same thread as other operations.


## 0.2.19

* Fixed issue that would cause Excel to crash when filtered columns were sorted


## 0.2.18

* Fixed issue where page would not scroll vertically if row was frozen
* Fixed issue where internal Row.cellCount() function would not return the correct number of cells if there were more than 9
* Fixed issue where invalid workbooks would be generated on write if write was called multiple times on the same workbook.


## 0.2.17

* Set string function to remove characters not compatible with XMLStringifier.
* merged pull request https://github.com/natergj/excel4node/pull/38 from https://github.com/nirarazi to add support for Right to Left languages


## 0.2.16

* merged pull request https://github.com/natergj/excel4node/pull/37 from https://github.com/pomeo to add ability to insert hyperlinks into cells


## 0.2.15

* fixed issue where Column functions were not returning Column objects and could not be chained
* fixed date issues with Cell Date function when invalid date was sent.
* fixed issue where merged cells would apply values to all cells in range rather than just top left cell. This would cause issues when summing rows and columns with merged cells.
* fixed issue where multiple images could not be added to a workbook


## 0.2.14

* Added ability to Group columns
* Merged pull request (https://github.com/natergj/excel4node/pull/34) from https://github.com/kylepixel which greatly optimizes conversion of numeric to and from alpha representations of columns


## 0.2.13

* Fixed issue where default style would inherit style alignement if it was delared prior to any other font declaration


## 0.2.12

* Added ability to Hide a Row or Column

      
## 0.2.11

* Merged pull request (https://github.com/natergj/excel4node/pull/32) from https://github.com/stefanhenze to add ability to set the fit to page on print
* Added the abilty to rotate text in cell
* fixed validation issue that would cause an error if a cell were written to as a formula after already being written to as a number or string


## 0.2.10

* Merged pull request (https://github.com/natergj/excel4node/pull/29) from https://github.com/atsapenko to fix issue when chaining style for date cell.


## 0.2.9

* Merged pull request (https://github.com/natergj/excel4node/pull/29) from https://github.com/atsapenko to add ability to set dropdown validation


## 0.2.8

* Merged pull request (https://github.com/natergj/excel4node/pull/27) from https://github.com/pookong to fix issue that would cause a numberformat to not apply to a cell


## 0.2.7

* fixed issue that would prevent cells to be written to columns over 702 (26^2 + 26) column AAA or higher
* Merged pull request (https://github.com/natergj/excel4node/pull/26) from https://github.com/RafaPolit to fixe continuing issue with merging cells


## 0.2.6

* fixed to merge issues after the 52nd column


## 0.2.5

* fixed the 2nd sort function needed for proper cell merging in all cases.


## 0.2.4

* fixed issue with cells not merging if one of the cells is after the 26th column.
* fixed xml validation issue if not style has been specified on the workbook.


## 0.2.3

* fixed issue where groupings would cause an XML validation error when summaryBelow was set to true
* greatly reduced memory usage when added data to worksheets
* deprecated Workbook.Settings.outlineSummaryBelow() call. This will be removed in version 1 and a console log entry created when used.


## 0.2.2

* fixed issue where incorrect string was displayed if cell had changed from a string to a number


## 0.2.1

* fixed issue that would cause failure if no cells had been added to a worksheet prior to write function called


## 0.2.0

* Near complete refactor. adds efficiency and speed and much more readable code.
* Added ability to create workbook with options. jszip options are first. more to come. Issue #20
* Added ability to create workshets with options. margins, zoom and centering on print first. more to come. Issue #19
* Added ability to add a Date to worksheet and set type as Date
* Fixed issue #22 where empty string would print 'undefined' in cell
* Fixed issue #21 where foreign characters would cause issue.


## 0.1.7

* Merged pull request (https://github.com/natergj/excel4node/pull/18) from https://github.com/daviesjamie
* Added Asynchronous abilty to write function


## 0.1.6

* added ability to set a row to be a Filter row
* finished Grouping feature


## 0.1.5

* fixed issue where some Excel features (sorting, grouping, etc) where not available on first sheet of workbook if more than one worksheet existed
* continuing work on experimental Grouping features


## 0.1.4

* fixed issue where sheet would not scroll properly if Freezing both a row and a column
* allowed for usage of color definitions in multiple formats


## 0.1.3

* added ability to Freeze Rows


## 0.1.2

* fixed issue with Font Alignment when applied directly to a cell
* module will no longer crash when String is passed an undefined value
* fixed sample to properly identify if it is running from within the module or not
* fixed issue where border would not always be applied to the correct cell range.


## 0.1.1

* added ability to merge cells
* added ability to apply styles to range of cells
* added ability to apply formatting to cells and cell ranges without first creating a style
* fixed issue that would cause error when applying a row height if row had populated cells


## 0.0.10

* merged pull request https://github.com/natergj/excel4node/pull/11


## 0.0.9

* fixed issue where if a Worksheet was added, but then no cells added, execution would stop
* fixed issue where workbooks would cause MS Excel for Windows to crash on print preview
* fixed issue where if undefined or 0 value was passed to cell or row function, execution would stop
* added changelog


## 0.0.8

* fixed issue where when adding a cell in a row not in sequence would cause corrupted excel data.


## 0.0.7

* added ability to add borders to cells


## 0.0.6

* added ability to include images in workbooks


## 0.0.5

* added ability to Freeze columns from horizontal scrolling
* fixed bug where if a Cell had been previously set to a String and is changed to a Number, the cell would reference the shared string key of the number rather than displaying the number.


## 0.0.4

* added ability to set text alignment of cells
* added ability to set text wrapping in cells
* fixed issue where fill were not being applied in certain circumstances


## 0.0.3

* fixed bug where excel data was corrupted if write function was called twice.


## 0.0.1

* initial push