function :avg do |args|
  args.reduce(0){|x,y| x + y} / args.size
end
