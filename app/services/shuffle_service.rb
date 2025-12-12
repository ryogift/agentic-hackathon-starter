class ShuffleService
  GROUP_NAMES = ("A".."Z").to_a.freeze

  def initialize(members, restaurants)
    @members = members.shuffle
    @restaurants = restaurants
  end

  def call
    group_sizes = calculate_group_sizes(@members.length)
    create_groups(group_sizes)
  end

  private

  def calculate_group_sizes(n)
    return [] if n < 3

    case n
    when 3 then [3]
    when 4 then [4]
    when 5 then [5]
    when 6 then [3, 3]
    when 7 then [4, 3]
    when 8 then [4, 4]
    when 9 then [3, 3, 3]
    when 10 then [4, 3, 3]
    when 11 then [4, 4, 3]
    else
      calculate_large_group_sizes(n)
    end
  end

  def calculate_large_group_sizes(n)
    sizes = []
    remaining = n

    while remaining > 0
      if remaining >= 8
        sizes << 4
        remaining -= 4
      elsif remaining == 7
        sizes << 4
        sizes << 3
        remaining = 0
      elsif remaining == 6
        sizes << 3
        sizes << 3
        remaining = 0
      elsif remaining == 5
        sizes << 5
        remaining = 0
      elsif remaining == 4
        sizes << 4
        remaining = 0
      elsif remaining == 3
        sizes << 3
        remaining = 0
      elsif remaining == 2
        # 2人余った場合、最後の3人グループを4人に、さらに1人を別グループに
        if sizes.include?(3)
          idx = sizes.rindex(3)
          sizes[idx] = 4
          remaining -= 1
        elsif sizes.include?(4)
          idx = sizes.rindex(4)
          sizes[idx] = 5
          remaining -= 1
        end
        # まだ1人残っている場合
        if remaining == 1 && sizes.include?(3)
          idx = sizes.rindex(3)
          sizes[idx] = 4
          remaining = 0
        elsif remaining == 1 && sizes.include?(4)
          idx = sizes.rindex(4)
          sizes[idx] = 5
          remaining = 0
        end
      elsif remaining == 1
        # 1人余った場合、既存の3人グループを4人に
        if sizes.include?(3)
          idx = sizes.rindex(3)
          sizes[idx] = 4
          remaining = 0
        elsif sizes.include?(4)
          idx = sizes.rindex(4)
          sizes[idx] = 5
          remaining = 0
        end
      end
    end

    sizes.sort.reverse
  end

  def create_groups(group_sizes)
    groups = []
    member_index = 0
    shuffled_restaurants = @restaurants.shuffle

    group_sizes.each_with_index do |size, index|
      group_members = @members[member_index, size]
      member_index += size

      restaurant = shuffled_restaurants[index % shuffled_restaurants.length]

      groups << {
        group_id: index + 1,
        group_name: "Team #{GROUP_NAMES[index]}",
        members: group_members,
        restaurant: restaurant
      }
    end

    groups
  end
end
