module Git
  
  class GitTagNameDoesNotExist< StandardError 
  end
  
  class Object
    
    class AbstractObject
      attr_accessor :sha, :size, :type, :mode
    
      @base = nil
    
      def initialize(base, sha)
        @base = base
        @sha = sha
        @size = @base.lib.object_size(@sha)
        setup
      end
    
      def contents
        @base.lib.object_contents(@sha)
      end
      
      def contents_array
        self.contents.split("\n")
      end
      
      def setup
        raise NotImplementedError
      end
      
      def to_s
        @sha
      end
      
      def grep(string, path_limiter = nil, opts = {})
        default = {:object => @sha, :path_limiter => path_limiter}
        grep_options = default.merge(opts)
        @base.lib.grep(string, grep_options)
      end
      
      def diff(objectish)
        Git::Diff.new(@base, @sha, objectish)
      end
      
      def log(count = 30)
        Git::Log.new(@base, count).object(@sha)
      end
      
    end
  
    
    class Blob < AbstractObject
      def setup
        @type = 'blob'
      end
    end
  
    class Tree < AbstractObject
      def setup
        @type = 'tree'
      end
    end
  
    class Commit < AbstractObject
      def setup
        @type = 'commit'
      end
    end
  
    class Tag < AbstractObject
      attr_accessor :name
      
      def initialize(base, sha, name)
        super(base, sha)
        @name = name
      end
      
      def setup
        @type = 'tag'
      end
    end
    
    class << self
      # if we're calling this, we don't know what type it is yet
      # so this is our little factory method
      def new(base, objectish, is_tag = false)
        if is_tag
          sha = base.lib.tag_sha(objectish)
          if sha == ''
            raise Git::GitTagNameDoesNotExist.new(objectish)
          end
          return Tag.new(base, sha, objectish)
        else
          sha = base.lib.revparse(objectish)
          type = base.lib.object_type(sha) 
        end
        
        klass =
          case type
          when /blob/:   Blob   
          when /commit/: Commit
          when /tree/:   Tree
          end
        klass::new(base, sha)
      end
    end 
    
  end
end