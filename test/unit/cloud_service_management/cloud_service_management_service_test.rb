#-------------------------------------------------------------------------
# Copyright 2013 Microsoft Open Technologies, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#--------------------------------------------------------------------------
require 'test_helper'

describe Azure::CloudServiceManagementService do

  subject { Azure::CloudServiceManagementService.new }
  let(:request_path) { '/services/hostedservices' }
  let(:cloud_services_xml) { Fixtures['list_cloud_services'] }
  let(:method) { :get }
  let(:mock_request) { mock }
  let(:response) do
    response = mock
    response.stubs(:body).returns(cloud_services_xml)
    response
  end
  let(:response_body) { Nokogiri::XML response.body }
  let(:slot) { "Staging" }
  let(:cloud_service_name) { "testservice" }
  let(:get_deployment_request_path) { "/services/hostedservices/#{cloud_service_name}/deploymentslots/#{slot}" }
  let(:deployment_xml) { Fixtures['get_deployment'] }
  let(:deployment_response) do
    response = mock
    response.stubs(:body).returns(deployment_xml)
    response
  end
  let(:deployment_response_body) { Nokogiri::XML deployment_response.body }

  before do
    Loggerx.expects(:puts).returns(nil).at_least(0)
  end

  describe '#list_cloud_services' do
    before do
      ManagementHttpRequest.stubs(:new).with(method, request_path, nil).returns(mock_request)
      mock_request.expects(:call).returns(response_body)
    end

    it 'assembles a URI for the request' do
      subject.list_cloud_services
    end

    it 'sets the properties of the CloudService instance' do
      cloud_service = subject.list_cloud_services.first
      cloud_service.name.must_equal 'cloud-service-1'
    end

    it 'returns a list of cloud services for the subscription' do
      results = subject.list_cloud_services
      results.must_be_kind_of Array
      results.length.must_equal 2
      results.first.must_be_kind_of Azure::CloudServiceManagement::CloudService
    end
  end

  describe '#get_cloud_service' do
    before do
      ManagementHttpRequest.stubs(:new).with(method, request_path, nil).returns(mock_request)
      mock_request.expects(:call).returns(response_body)
    end

    it 'assembles a URI for the request' do
      subject.get_cloud_service 'cloud-service-1'
    end

    it 'returns true if found cloud service with given name' do
      result = subject.get_cloud_service 'cloud-service-1'
      result.must_equal true
    end

    it "returns false if cloud service with given name doesn't exists" do
      result = subject.get_cloud_service 'cloud-service-3'
      result.must_equal false
    end
  end

  describe '#create_cloud_service' do

    it 'Create cloud service return message if cloud service exists of given name.' do
      ManagementHttpRequest.any_instance.expects(:call).returns response_body
      msg = subject.create_cloud_service 'cloud-service-1'
      assert_match(/^Cloud service cloud-service-1 already exists*/, msg)
    end

    it "Create cloud service if cloud service doesn't exists of given name." do
      Azure::CloudServiceManagementService.any_instance.stubs(:get_cloud_service).with('cloud-service-3').returns(false)
      ManagementHttpRequest.any_instance.expects(:call).returns nil
      subject.create_cloud_service 'cloud-service-3'
    end

  end

  describe '#get_deployment' do
  	before do
  		ManagementHttpRequest.stubs(:new).with(method, get_deployment_request_path, nil).returns(mock_request)
  		mock_request.expects(:call).returns(deployment_response_body)
  	end

  	it 'Return a Deployment object with all its statuses and details if the it exists for the specific cloud service and slot.' do
  		deployment = subject.get_deployment(cloud_service_name, {:slot => slot})
  		deployment.must_be_kind_of Azure::CloudServiceManagement::Deployment
  		deployment.deployment_slot.must_equal slot
  		deployment.role_instances.size.must_equal 1
  		deployment.role_instances[0].instance_endpoints.size.must_equal 3
  		deployment.roles.size.must_equal 1
  		deployment.roles[0].configuration_sets.size.must_equal 1
  		deployment.virtual_ips.size.must_equal 1
  	end
  end
end
