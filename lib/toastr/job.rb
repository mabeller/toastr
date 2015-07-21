module Toastr
  class Job < ActiveJob::Base
    def perform(toast, options = {})
      elapsed = Benchmark.realtime { @result = toast.parent.send("#{toast.category}_for_toastr") }
      toast.cache_json = @result.merge({toastr: { elapsed: elapsed, cached_at: Time.now }})

      toast.complete!
    end

  end
end
