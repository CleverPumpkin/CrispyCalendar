Pod::Spec.new do |spec|
	spec.name         = 'CrispyCalendar'
	spec.version      = '1.0.5'
	spec.license      = { :type => 'MIT' }
	spec.homepage     = "https://github.com/CleverPumpkin/crispycalendar"
	spec.authors      = { 'Cleverpumpkin, Ltd.' => 'cleverpumpkin.ru' }
	spec.summary      = 'Highly performant and customizable calendar UI library written with lots of attention to various localization differences.'
	spec.source       = { :git => "#{spec.homepage}.git", :tag => "v#{spec.version}" }
	spec.requires_arc = true
	
	spec.ios.deployment_target = '10.3'
	spec.swift_version         = '5.0'
	spec.source_files          = "#{spec.name}/**/*.{h,c,m,swift}"
	spec.public_header_files   = "#{spec.name}/**/*.h"
	spec.private_header_files   = "#{spec.name}/View/CPCDayCellRenderer.h"
	spec.module_map            = "#{spec.name}/Supporting Files/#{spec.name}.modulemap"
	spec.frameworks            = 'UIKit'
end
