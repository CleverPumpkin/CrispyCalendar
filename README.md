![crispycalendar](https://user-images.githubusercontent.com/2410233/47371768-09856680-d6f1-11e8-8aff-2e8418cdc1cb.png)

Whether you are writing yet another one task tracker or calendar app, or simply want to offer the users to skip the joy of using `UIDatePicker` and let them quickly and efficiently select dates — CrispyCalendar is **the** calendar UI framework you need.

[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/CrispyCalendar.svg?style=popout)](https://cocoapods.org/pods/CrispyCalendar)
![Platform support](https://img.shields.io/cocoapods/p/CrispyCalendar.svg?style=popout)
[![Documentation](https://img.shields.io/cocoapods/metrics/doc-percent/CrispyCalendar.svg?style=popout)](https://cleverpumpkin.github.io/CrispyCalendarDocs/public/)
[![License](https://img.shields.io/cocoapods/l/CrispyCalendar.svg?style=popout)](https://github.com/ReSwift/ReSwift/blob/master/LICENSE.md)

## Features

* **Written with localization in mind.**<br/>
  Specifically, many various (and even nonsensical) combinations of calendar types, locale identifiers
  and writing directions were tested. Also, this framework does not contain a single translation error
  simply because only standard Apple frameworks (hence, their translations) are being used and none of
  third-party code.
* **Ease of integration, customization options and extensibility — you are free to choose any and all of those.**<br/>
  The framework contains out-of-the-box components for the most common tasks; in many cases a single line of
  code allows you to employ rich user interfaces, allowing you to concentrate on business logic implementation.
  But at the same time, every such solution is thoroughly equipped with tuning possibilities and is designed
  modularly, allowing you to freely reuse and combine basic blocks to suite your specific requests.
* **Optimized for performance.**<br/>
  Even seasoned devices like iPhone 5 are rendering the calendar at the acceptable frame rate to say the least.
  Minor sacrifices had to be made to achieve that, but the overall result is shining nonetheless.
* **Objective C support.**<br/>
  Whether you are constrained by legacy code or just not ready for Swift in production-grade code yet, using
  CrispyCalendar from Objective C is possible. Mostly, Swift-specific features only are missing, but blind
  spots here and there are possible.

## Getting Started

* [Getting Started](https://cleverpumpkin.github.io/CrispyCalendarDocs/public/getting-started.html) contains framework overview and describes basic concepts.
* Common usage patterns and various examples of code can be found in [Examples](https://cleverpumpkin.github.io/CrispyCalendarDocs/public/Guides.html) directory.
* [Demo project](CrispyCalendar.xcodeproj).
* [API Reference](https://cleverpumpkin.github.io/CrispyCalendarDocs/public/index.html) contains detailed
  descriptions of the vast majority of `public` & `open` types and identifiers.
* [Internals Reference](https://cleverpumpkin.github.io/CrispyCalendarDocs/internal/index.html) lays out
  a number of internal design decisions and rationale. Its completeness is far from ideal but there is an
  ongoing work.

## Installation

### Cocoapods (preferred)

CocoaPods is a dependency manager for Swift and Objective-C Cocoa projects. It has over 53 thousand libraries and is used in over 3 million apps. More details and installation instructions may be found here: [Using Cocoapods](https://guides.cocoapods.org/using/getting-started.html).

To integrate CrispyCalendar into your Xcode project using CocoaPods, specify it in your Podfile:
```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.3'

target 'TargetName' do
    pod 'CrispyCalendar', '~> 1.0.0'
end
```

Then, run the following command:

```$ pod install```

### Manual

Open [Demo project](CrispyCalendar.xcodeproj) in Xcode and build `CrispyCalendar` framework target.
Then, embed it into your project and add it to `Linked Frameworks and Libraries` section of app target.

## Screenshots

### Appearance customization

All the fonts, colors and other appearance details are customizable via corresponding properties. [CPCCalendarView](https://cleverpumpkin.github.io/CrispyCalendarDocs/public/Classes/CPCCalendarView.html) does also support customization via [UIAppearance](https://developer.apple.com/documentation/uikit/uiappearance) for properties representable in Objective C.


<table>
<tr><th>Default</th><th>Basic from Debt Control</th><th>Input view from Debt Control</th></tr>
<tr><td>
  <img src="https://user-images.githubusercontent.com/2410233/47380929-5116ed00-d707-11e8-8395-c8fdf3ef4740.png" alt="default" width="375" />
</td><td>
  <img src="https://user-images.githubusercontent.com/2410233/47381603-18781300-d709-11e8-9346-44f92c7aca13.png" alt="basic" width="375" />
</td><td>
	<img src="https://user-images.githubusercontent.com/2410233/47381605-18781300-d709-11e8-9208-1479228e4c70.png" alt="inputview" width="375" />
</td></tr></table>

### Simple selection

Prebuilt UI commonly uses [CPCMonthView](https://cleverpumpkin.github.io/CrispyCalendarDocs/public/Classes/CPCMonthView.html) capable of displaying single month. [CPCMultiMonthsView](https://cleverpumpkin.github.io/CrispyCalendarDocs/public/Classes/CPCMultiMonthsView.html) may be used as container for month views allowing shared selection handling and other functionality.

<table>
<tr><th>Single day selection</th><th>Days range selection</th></tr>
<tr><td>
  &lt;TBD GIF Single selection&gt;
</td><td>
  &lt;TBD GIF Range selection&gt;
</td></tr></table>

### Ordered & unordered selection

Selection process is fully controlled externally by corresponding view's delegate. Note that delegates for views inside containers are not supported.

<table>
<tr><th>Single day selection</th><th>Days range selection</th></tr>
<tr><td>
  &lt;TBD GIF Ordered selection&gt;
</td><td>
  &lt;TBD GIF Unordered selection&gt;
</td></tr></table>

### Custom draw handlers

[CPCMonthView](https://cleverpumpkin.github.io/CrispyCalendarDocs/public/Classes/CPCMonthView.html) does not comprise any real child views but is logically drawn from title "label" and "grid", consisting of "day cells". Custom day rendering is supported via custom [CPCDayCellRenderer](https://cleverpumpkin.github.io/CrispyCalendarDocs/public/Protocols/CPCDayCellRenderer.html)s.

<table>
<tr><th>Custom cell renderer example</th></tr>
</td><td>
  &lt;TBD GIF Custom rendering&gt;
</td></tr></table>

### Localization

Locale used by any component cannot be set explicitly, but Calendar's locale is honored. The framework uses `[[[NSBundle mainBundle] preferredLocalizations] firstObject]` as default locale, including setting it for calendars without explicitly set locale.

<table>
<tr><th>Non-gregorian calendar rendering</th></tr>
</td><td>
  &lt;TBD GIF Hebrew calendar&gt;
</td></tr></table>

### Other

Available dates limiting, RTL and landscape orientation are fully supported.

<table>
<tr><th>Dates limiting</th><th>RTL layout</th></tr>
<tr><td>
  &lt;TBD GIF Dates limiting&gt;
</td><td>
  &lt;TBD GIF Flipped&gt;
</td></tr></table>


<table>
<tr><th>Columned mode</th></tr>
<tr><td>
  &lt;TBD GIF Landscape view&gt;
</td></tr></table>

## Credits

CrispyCalendar is owned and maintained by the [Cleverpumpkin, Ltd](https://cleverpumpkin.ru).

CrispyCalendar was originally created by [Kirill Bystrov](https://github.com/byss) as a response to lack of quality calendar-rendering libraries. Android couterpart does exist (but neither API nor UX is similar), check it out here: [CrunchyCalendar](https://github.com/CleverPumpkin/CrunchyCalendar).

## License

CrispyCalendar is released under the MIT license. See [LICENSE](./LICENSE) for details.
