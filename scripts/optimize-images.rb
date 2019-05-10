#!/usr/bin/ruby

require "image_optim"
require "image_optim/space"

def percent(old_size, new_size)
    return format("%.2f%%", 100 - 100.0 * new_size / old_size)
end

def file_size(size)
    return ImageOptim::Space.space(size).strip()
end

def line(name, old_size, new_size)
    return "| #{name} | #{file_size(old_size)} | #{file_size(new_size)} | #{percent(old_size, new_size)} |"
end

image_optim = ImageOptim.new(
    :nice => 0,
    :pngout => false,
    :svgo => {
        :enable_plugins => [
            # All lossless according to ImageOptim:
            # https://github.com/ImageOptim/ImageOptim/blob/fc4d2a02228f799ca68c60e7c5285c7d745458e9/svgo/index.js#L6-L23
            "cleanupAttrs","cleanupListOfValues","cleanupNumericValues","convertColors","convertStyleToAttrs",
            "minifyStyles","moveGroupAttrsToElems","removeComments","removeDoctype","removeEditorsNSData",
            "removeEmptyAttrs","removeEmptyContainers","removeEmptyText","removeNonInheritableGroupAttrs",
            "removeXMLProcInst","sortAttrs"
        ]
    }
)

min_files = ARGV[0].to_i
min_size = ARGV[1].to_f * (1024 ** 2)
exclude_paths = ARGV[2..]

paths = Dir.glob("**/*").reject { |f| File.directory?(f) }
if !exclude_paths.empty?
    paths = paths.reject { |f| f.start_with?(*exclude_paths) }
end

results = ["| File | Original size | Optimized size | Reduction |", "| --- | --- | --- | --- |"]
old_size = 0
new_size = 0

image_optim.optimize_images!(paths) do |_, optimized|
    if optimized
        results << line(optimized, optimized.original_size, optimized.size)
        old_size += optimized.original_size
        new_size += optimized.size
    end
end

if results.size >= 2 + min_files && old_size - new_size >= min_size
    results << "| **Total** | **#{file_size(old_size)}** | **#{file_size(new_size)}** | **#{percent(old_size, new_size)}** |"
    puts results
end
