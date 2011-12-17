require 'process_shared/rt'
require 'process_shared/libc'
require 'process_shared/with_self'

module ProcessShared
  # Memory block shared across processes. TODO: finalizer that closes...
  class SharedMemory < FFI::Pointer
    include WithSelf

    attr_reader :size, :fd

    def self.open(size, &block)
      new(size).with_self(&block)
    end

    def self.make_finalizer(addr, size, fd)
      proc do
        pointer = FFI::Pointer.new(addr)
        LibC.munmap(pointer, size)
        LibC.close(fd)
      end
    end

    def initialize(size)
      @size = case size
              when Symbol
                FFI.type_size(size)
              else
                size
              end

      name = "/ps-shm#{rand(10000)}"
      @fd = RT.shm_open(name,
                        LibC::O_CREAT | LibC::O_RDWR | LibC::O_EXCL,
                        0777)
      RT.shm_unlink(name)
      
      LibC.ftruncate(@fd, @size)
      @pointer = LibC.mmap(nil,
                           @size,
                           LibC::PROT_READ | LibC::PROT_WRITE,
                           LibC::MAP_SHARED,
                           @fd,
                           0)

      @finalize = self.class.make_finalizer(@pointer.address, @size, @fd)
      ObjectSpace.define_finalizer(self, @finalize)

      super(@pointer)
    end

    def close
      ObjectSpace.undefine_finalizer(self)
      @finalize.call
    end
  end
end
