require 'genetica'
require 'RMagick'


# Loading source image
SOURCE_IMAGE = Magick::Image.read("monalisa_400.png").first

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

NUMBER_CIRCLES = 50
CHROMOSOME_LENGTH = NUMBER_CIRCLES * LENGTH_CIRCLE

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
  chromosome.chromosome.each_slice(LENGTH_CIRCLE) do |binary_circle|
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

def fitness_image_distance(chromosome)
  return 1 / (image_distance SOURCE_IMAGE, render_chromosome(chromosome)).to_f  
end

# Setting Population Builder
population_builder = Genetica::PopulationBuilder.new
population_builder.size = 10                                           # Population size
population_builder.crossover_probability = 0.7                         # Crossover rate
population_builder.mutation_probability = 0.01                         # Mutation rate
population_builder.chromosome_length = CHROMOSOME_LENGTH               # Chromosome length
population_builder.chromosome_alleles = [0, 1]                         # Chromosome alleles
population_builder.fitness_function = method(:fitness_image_distance)  # Fitness Function

# Get Population
population = population_builder.population

# Running
loop do
  population.run generations=1

  # Saving best Chromosome as an image
  best_image = render_chromosome population.best_chromosome
  best_image.write("results/generation_#{population.generation}.png")

  # Show some information about the population
  puts "generation: #{population.generation}, best_fitness: #{population.best_fitness}, average_fitness: #{population.average_fitness}"
end
