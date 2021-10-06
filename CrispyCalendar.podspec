Pod::Spec.new do |spec|
	spec.name              = 'CrispyCalendar'
	spec.version           = '1.0.3'
	spec.license           = { :type => 'MIT' }
	spec.homepage          = "https://github.com/CleverPumpkin/CrispyCalendar"
	spec.documentation_url = "https://cleverpumpkin.github.io/CrispyCalendarDocs/public/"
	spec.authors           = { 'Cleverpumpkin, Ltd.' => 'cleverpumpkin.ru' }
	spec.summary           = 'Highly performant and customizable calendar UI library written with lots of attention to various localization differences.'
	spec.source            = { :git => "#{spec.homepage}.git", :tag => "v#{spec.version}" }
	
	spec.ios.deployment_target = '10.3'
	spec.swift_version         = '5.0'
	spec.pod_target_xcconfig   = { 'DEFINES_MODULE' => 'YES' }
	spec.source_files          = "#{spec.name}/**/*.{h,c,m,swift}"
	spec.public_header_files   = "#{spec.name}/**/*.h"
	spec.private_header_files  = "#{spec.name}/View/CPCDayCellRenderer.h"
	spec.module_map            = "#{spec.name}/Supporting Files/#{spec.name}.modulemap"
	spec.requires_arc          = true
	spec.frameworks            = 'UIKit'
end
