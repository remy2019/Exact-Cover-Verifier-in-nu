let create_rand_row = { |bits: int, x: int|
  if $x == 0 {
    []
  } else {
    (1..$x) | each { |_|
      (1..$bits) | each { |_|
        random int 0..1
      } | str join
    }
  }
}

let gen_guaranteed = { |bits: int, x: int|
  let row_info = (1..$bits) | each { |_| random int 1..$x}
  let rows = $row_info | reduce --fold [] { |it, acc|
    $acc | insert 0 $it
  }
  let rows = $rows | each { |i|
    (1..$x) | each { |j|
      if $i == $j { 1 } else { 0 }
    }
  }

  # Transpose
  let rows = (1..$x) | each { |i|
    (1..$bits) | each { |j|
      $rows | get ($j - 1) | get ($i - 1)
    } | str join
  }
  $rows
}

# 보장되는 경우: UNSAT 나오면 틀림  SAT 나오면 확인(다른 답이 생길 수 있음)
let sat = { ||
    let elem = random int $env.min_elem..$env.max_elem
    let sets = random int $env.min_sets..$env.max_sets

    let guaranteed_row_num = random int 1..$sets
    let not_guaranteed_row_num = $sets - $guaranteed_row_num

    let guaranteed = do $gen_guaranteed $elem $guaranteed_row_num
    let not_guaranteed = do $create_rand_row $elem $not_guaranteed_row_num
    let final = $guaranteed | append $not_guaranteed | shuffle
    [$elem $sets $final]
}


# total random: 보장되지 않는 경우:  UNSAT나오면 ㅇㅋ(매뉴얼하게 확인).  SAT -> 매뉴얼 확인만 하면  됨
let generate_unsat = { |bits: int, x: int|
  let sat = do $gen_guaranteed $bits $x | sort
  $sat | enumerate | each { |i|
    if $i.index == 0 {
      $i.item | split chars | enumerate | each { |x|
        if $x.index == 0 {
          if $x.item == "0" { "1" } else { "0" }
        } else {
          $x.item
        }
      } | str join
    } else {
      $i.item
    }
  } | shuffle
}

let gen_sets = { |index: int, set|
  let elem = $set | get 0
  let sets = $set | get 1
  let lists = $set | get 2
  let first_line = $"let datasets($index) : sets = \(($sets), ($elem),"
  let second_line = "["
  let body = $lists | each { |line|
    let cargo = $line | split chars | str join ';' 
    $"  [($cargo)];"
  }
  let trail = "])"
  [$first_line $second_line] | append $body | insert (($body | length) + 2) $trail | str join (char newline)
}

let create_main_ml = { |n: int|
  let dep = ["open Utils" "open Cover" "open Datasets"]
  let cargo = (1..$n) | each { |i|
    $"let _ = print_endline \(string_of_list string_of_int \(solve \(encode datasets($i))))"
  }
  $dep | append $cargo | str join (char newline)
}

let verify_sat = { |n, data, result|
  (0..<$n) | each { |i|
    let origin_raw = $data | get $i
    let elem = $origin_raw | get 0
    let sets = $origin_raw | get 1
    let origin = $origin_raw | get 2

    let recv_raw = $result | get $i
    let recv = $recv_raw | str replace "(" "" | str replace ")" "" | split column ',' | transpose -i | get 'column0'
    let counter = (0..<$elem) | each { |i| 0 }
    let res = $recv | reduce --fold $counter { |index, acc|
      let target = $origin | get (($index | into int) - 1) | split chars
      $target | enumerate | reduce --fold $acc { |j, c|
        if $j.item == "1" {$c | update $j.index {|x| $x + 1}} else { $c }
      }
    }
    $res | all { |e| $e == 1}
  }
}

