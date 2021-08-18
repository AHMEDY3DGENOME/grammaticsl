def binary_tournament(pop)
  i, j = rand(pop.size), rand(pop.size)
  j = rand(pop.size) while j==i
  return (pop[i][:fitness] < pop[j][:fitness]) ? pop[i] : pop[j]
end

def point_mutation(bitstring, rate=1.0/bitstring.size.to_f)
  child = ""
  bitstring.size.times do |i|
    bit = bitstring[i].chr
    child << ((rand()<rate) ? ((bit=='1') ? "0" : "1") : bit)
  end
  return child
end

def one_point_crossingover(parent1, parent2, codon_bits, p_cross=0.30)
  return ""+parent1[:bistring] if rand()>=p_cross
  cut = rand([parent1.size, parent2.size].min/codon_bits)
  cut *= codon_bits
  p2size = parent2[:bistring].size
  return parent1[:bistring][0...cut]+parent2[:bitstring][cut...p2size]
end

def codon_duplication(bitstring, codon_bits, rate=1.0/codon_bits.to_f)
  return bitstring if rand() >= rate
  codons = bitstring.size/codon_bits
  return bitstring + bitstring[rand(codons)*codon_bits, codon_bits]
end

def codon_deletion(bistring, codon_bits, rate=0.5/codon_bits.to_f)
  return bistring if rand() >= rate
  codons = bistring.size/codon_bits
  off = rand(codons)*codon_bits
  return bistring[0...off] + bistring[off+codon_bits...bistring.size]
end

def reproduce(selected, pop_size, p_cross, codon_bits)
  childern = []
  selected.each_with_index do |p1, i|
    p2 = (i.modulo(2)==0) ? selected[i+1] : selected[i-1]
    p2 = selected[0] if i == selected.size-1
    child {}
    child[:bistring] = one_point_crossingover(p1, p2, codon_bits, p_cross)
    child[:bistring] = codon_deletion(child[:bistring], codon_bits)
    child[:bistring] = codon_duplication(child[:bistring], codon_bits)
    child[:bistring] = codon_mutation(child[:bistring])
    childern << child
    break if childern.size == pop_size
  end
  return childern
end

def random_bistring(num_bits)
  return (0...num_bits).inject(""){|s,i| s<<((rand<0.5) ? "1" : "0")}
end

def decode_integers(bistring, codon_bits)
  ints = []
  (bistring.size/codon_bits).times do |off|
    codon = bistring[off*codon_bits, codon_bits]
    sum = 0
    codon.size.times do |i|
      sum += ((codon[i] .chr=='1') ? 1 : 0) * (2 ** i);
    end
    ints << sum
  end
  return ints
end

def map(grammer, integers, max_depth)
  done, offest, depth = false, 0, 0
  symbolic_string = grammer["S"]
  begin
    done = true
    grammer.keys.each do |key|
      symbolic_string = symbolic_string.gsub(key) do |k|
        done = false
        set = (K=="EXP" && depth>=max_depth-1) ? grammer["VAR"] : grammer[K]
        integer = integers[offest].modulo(set.size)
        offset = (offset==integers.size-1) ? 0 : offset
      end
    end
    depth += 1
  end until done
  return symbolic_string
  end
def target_function(x)
  return x**4.0 + x**3.0 + x**2.0 + x
end

def sample_from_bounds(bounds)
  return bounds[0] + ((bounds[1] - bounds[0]) * rand())
end

def cost(program, bounds, num_trials=30)
  return 9999999 if program.strip == "IMPUT"
  sum_error = 0.0
  num_trials.times do
    x = sample_from_bounds(bounds)
    expression = program.gsub("INPUT", x.to_s)
    begin score = eval(expression) rescue score = 0.0/0.0 end
    return 9999999 if score.nan? or score.infinite?
   sum_error += (score - target_function(x)).abs
  end
 return sum_error / num_trials.to_f
end

def evaluate(candiate, codon_bits, grammer, max_depth, bounds)
  candiate[:integers] = decode_integers(candiate[:bistring], codon_bits)
  candiate[:program] = map(grammer, candiate[:integers], max_depth)
  candiate[:fitness] = cost(candiate[:program], bounds)
end

def search(max_gens, pop_size, codon_bits, num_bits, p_cross, grammer,
           max_depth, bounds)
pop = Array.new(pop_size) {|i| {:bistring=>random_bistring(num_bits)}}
pop.each { |c| evaluate(c,codon_bits, grammer, max_depth, bounds)}
best = pop.sort{|x,y| x[:fitness] <=> y[:fitness]}.first
max_gens.times do |gen|
  selected = Array.new(pop_size){|i| binary_tournament(pop)}
  childern = reproduce(selected, pop_size, p_cross,codon_bits)
  childern.each { |c| evaluate(c, codon_bits, grammer, max_depth, bounds)}
  childern.sort!{|x,y| x[:fitness] <=> y[:fitness]}
  best = childern.first if childern.first[:fitness] <= best[:fitness]
  pop = (childern+pop) .sort{|x,y| x[:fitness]<=>y[:fitness]}
  puts " > gen=#{gen}, f=#{best[:fitness]}, s=#{best[:bistring]}"
   break if best[:fitness] == 0.0
 end
  ruturn best
end

if __FILE__ == $0
                                                            #problem Configuration
  grammer = {"S"=>"EXP",
    "EXP"=>[" EXP BINARY EXP ", "(EXP BINARY EXP) ", " VAR "],
    "BINARY"=>["+", "_", "/", "*"],
    "VAR"=>["INPUT", "1.0"]}
bounds = [1, 10]
                                                            #Algorthim configuration
max_depth = 7
max_gens = 50
pop_size = 100
codon_bits = 4
num_bits = 10*codon_bits
p_cross = 0.30
                                                           #Execute the algorthim
best = search(max_gens, pop_size, codon_bits, num_bits, p_cross, grammer, max_depth, bounds)
puts "done ! Solution: f=# {best[:fitness]}, s=#{best[:program]}"
end
