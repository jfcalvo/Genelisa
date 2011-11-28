#!/usr/bin/env ruby

require 'genetica'
require 'RMagick'

SERIALIZED_FILE = 'population.marshal'

class GenelisaPopulation < Genetica::Population

  # Source image
  SOURCE_IMAGE = Magick::Image.read('monalisa_400.png').first

  # Chromosome length measured in bits
  LENGTH_WIDTH  = SOURCE_IMAGE.columns.to_s(2).size
  LENGTH_HEIGHT = SOURCE_IMAGE.rows.to_s(2).size
  LENGTH_RADIUS = [LENGTH_WIDTH, LENGTH_HEIGHT].max
  LENGTH_RED    = 8
  LENGTH_GREEN  = 8
  LENGTH_BLUE   = 8
  LENGTH_ALPHA  = 8

  LENGTH_COLOR  = LENGTH_RED + LENGTH_GREEN + LENGTH_BLUE + LENGTH_ALPHA
  LENGTH_CIRCLE = LENGTH_WIDTH + LENGTH_HEIGHT + LENGTH_RADIUS + LENGTH_COLOR

  NUMBER_CIRCLES = 20
  CHROMOSOME_LENGTH = NUMBER_CIRCLES * LENGTH_CIRCLE

  def fitness(chromosome)
    return 1 / (self.image_distance SOURCE_IMAGE, self.render_chromosome(chromosome)).to_f  
  end

  def run
    loop do
      super generations=1

      # Saving best Chromosome as an image
      best_image = render_chromosome self.best_chromosome
      best_image.write("results/generation_#{self.generation}.png")

      # Show some information about the population
      puts "generation: #{self.generation}, best_fitness: #{self.best_fitness}, average_fitness: #{self.average_fitness}"
    end
  end
  
  def image_distance(image1, image2)
    total_distance = 0
    
    for x in 0...image1.columns
      for y in 0...image1.rows
        c1 = image1.pixel_color x, y
        c2 = image2.pixel_color x, y

        # Delta Color
        delta_red = c1.red - c2.red
        delta_green = c1.green - c2.green
        delta_blue = c1.blue - c2.blue

        # Distance between colors in 3D space
        pixel_distance = delta_red**2 + delta_green**2 + delta_blue**2

        # Add the pixel distance to the total image distance (lower is better)
        total_distance += pixel_distance
      end
    end

    return total_distance
  end

  def render_chromosome(chromosome)
    # Creating the image to be render with the content of chromosomes
    render_image = Magick::Image.new(SOURCE_IMAGE.columns, SOURCE_IMAGE.rows) { self.background_color = 'black' }

    # Drawing circles from chromosome binary data
    chromosome.each_slice(LENGTH_CIRCLE) do |binary_circle|
      # Get data from binary circle chromosome information
      x      = binary_circle.shift(LENGTH_WIDTH).join.to_i(2)
      y      = binary_circle.shift(LENGTH_HEIGHT).join.to_i(2)
      radius = binary_circle.shift(LENGTH_RADIUS).join.to_i(2)
      red    = binary_circle.shift(LENGTH_RED).join.to_i(2)
      green  = binary_circle.shift(LENGTH_GREEN).join.to_i(2)
      blue   = binary_circle.shift(LENGTH_BLUE).join.to_i(2)
      alpha  = (binary_circle.shift(LENGTH_ALPHA).join.to_i(2) / 250.0).round 2

      circle = Magick::Draw.new
      circle.fill("rgba(#{red}, #{green}, #{blue}, #{alpha})")
      circle.circle(x, y, x+radius, y)
      circle.draw(render_image)
    end

    return render_image
  end

end


if File.exists? SERIALIZED_FILE
  population = Marshal.load(File.read SERIALIZED_FILE)
  puts "Loaded #{SERIALIZED_FILE} from disk"
else
  # Setting Population Builder
  population_builder = Genetica::PopulationBuilder.new
  population_builder.population_class = GenelisaPopulation # Set the class of the Population to build
  population_builder.elitism = 2                           # Activating elitism in population selection
  population_builder.size = 10                             # Population size
  population_builder.crossover_probability = 0.7           # Crossover rate
  population_builder.mutation_probability = 0.002          # Mutation rate
  population_builder.chromosome_length = GenelisaPopulation::CHROMOSOME_LENGTH # Chromosome length
  population_builder.chromosome_alleles = [0, 1]           # Chromosome alleles

  # Get Population
  population = population_builder.population
end

# Runn Population
trap("SIGINT") { throw :ctrl_c }

catch :ctrl_c do
  begin
    puts "Running population..."
    population.run
  ensure
    # Serializating Population
    serialization = Marshal.dump(population)
    serialization_file = File.new SERIALIZED_FILE, 'w'
    serialization_file.write serialization
    serialization_file.close
    puts "Writed #{SERIALIZED_FILE} to disk"
  end
end
