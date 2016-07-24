Pod::Spec.new do |s|
  s.name         = 'SCAStateMachine'
  s.version      = '0.2.0'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.summary      = 'A lightweight state machine built in Swift.'
  s.homepage     = 'https://github.com/seancatkinson/SCAStateMachine'
  s.social_media_url = "https://twitter.com/seancatkinson"
  s.authors      = { 'Sean Atkinson' => "seanca.seanca@gmail.com" }
  s.source       = { :git => 'https://github.com/seancatkinson/SCAStateMachine.git',
                     :tag => s.version.to_s }
  
  s.ios.deployment_target = '8.1'
  s.osx.deployment_target = '10.10'

  s.source_files = 'Source/*.swift'
  
  s.requires_arc = true
end

