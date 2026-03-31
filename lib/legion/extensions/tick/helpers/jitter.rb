# frozen_string_literal: true

module Legion
  module Extensions
    module Tick
      module Helpers
        module Jitter
          MAX_JITTER_CAP = 900 # seconds (15 minutes)

          module_function

          # Returns a deterministic integer jitter offset (seconds) for the given task name
          # and interval. The offset is in the range [0, max_jitter) where max_jitter is
          # 10% of the interval, capped at MAX_JITTER_CAP (15 minutes).
          #
          # The same task_name always produces the same offset, so all nodes handling the
          # same named task will sleep the same initial amount — preventing thundering herd
          # while keeping execution predictable.
          def deterministic_jitter(task_name, interval_seconds)
            max_jitter = [interval_seconds * 0.1, MAX_JITTER_CAP].min.to_i
            return 0 if max_jitter < 1

            task_name.to_s.hash.abs % max_jitter
          end

          # Returns true when jitter is enabled via settings (default: true).
          def jitter_enabled?
            setting = begin
              Legion::Settings[:tick]
            rescue StandardError => _e
              nil
            end
            return true if setting.nil?

            tick_hash = setting.is_a?(Hash) ? setting : nil
            return true if tick_hash.nil?

            tick_hash.fetch(:jitter_enabled, true)
          end
        end
      end
    end
  end
end
