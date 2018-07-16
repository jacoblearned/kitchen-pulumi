# frozen_string_literal: true

def in_tmp_dir
  Dir.mktmpdir do |dir|
    Dir.chdir(dir) do
      yield if block_given?
    end
  end
end

def in_tmp_project_dir(support_project_name)
  project_dir = File.absolute_path("spec/support/#{support_project_name}")

  in_tmp_dir do
    FileUtils.cp_r("#{project_dir}/.", Dir.getwd)
    yield if block_given?
  end
end
