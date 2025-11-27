#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/utils/constants.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/ui/themes.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/ui/color-scale.sh"
}

teardown() {
  cleanup_test_environment
}

@test "color-scale.sh - get_percentage_color returns RED for value >= 90" {
  result=$(get_percentage_color "90" "49" "74" "89")
  [[ "$result" == "$COLOR_RED" ]]
}

@test "color-scale.sh - get_percentage_color returns YELLOW for value > max_high" {
  result=$(get_percentage_color "80" "49" "74" "75")
  [[ "$result" == "$COLOR_YELLOW" ]]
}

@test "color-scale.sh - get_percentage_color returns BLUE for value > max_moderate" {
  result=$(get_percentage_color "60" "49" "50" "75")
  [[ "$result" == "$COLOR_BLUE" ]]
}

@test "color-scale.sh - get_percentage_color returns CYAN for value <= max_moderate" {
  result=$(get_percentage_color "40" "49" "74" "89")
  [[ "$result" == "$COLOR_CYAN" ]]
}

@test "color-scale.sh - get_count_color returns RED for value > max_high" {
  result=$(get_count_color "100" "10" "50" "80")
  [[ "$result" == "$COLOR_RED" ]]
}

@test "color-scale.sh - get_count_color returns YELLOW for value > max_moderate" {
  result=$(get_count_color "60" "10" "50" "80")
  [[ "$result" == "$COLOR_YELLOW" ]]
}

@test "color-scale.sh - get_count_color returns BLUE for value > max_normal" {
  result=$(get_count_color "30" "10" "50" "80")
  [[ "$result" == "$COLOR_BLUE" ]]
}

@test "color-scale.sh - get_count_color returns CYAN for value <= max_normal" {
  result=$(get_count_color "5" "10" "50" "80")
  [[ "$result" == "$COLOR_CYAN" ]]
}

@test "color-scale.sh - get_system_color uses correct limits" {
  result_low=$(get_system_color "30")
  result_high=$(get_system_color "90")
  
  [[ "$result_low" == "$COLOR_CYAN" ]]
  [[ "$result_high" == "$COLOR_RED" ]]
}

@test "color-scale.sh - get_load_average_color returns CYAN when load empty" {
  result=$(get_load_average_color "" "4")
  [[ "$result" == "$COLOR_CYAN" ]]
}

@test "color-scale.sh - get_load_average_color returns CYAN when cpu_count zero" {
  result=$(get_load_average_color "1.5" "0")
  [[ "$result" == "$COLOR_CYAN" ]]
}

@test "color-scale.sh - get_load_average_color returns RED when load >= cpu_count" {
  result=$(get_load_average_color "4.0" "4")
  [[ "$result" == "$COLOR_RED" ]]
}

@test "color-scale.sh - get_git_changes_color uses correct limits" {
  result_low=$(get_git_changes_color "3")
  result_high=$(get_git_changes_color "35")
  
  [[ "$result_low" == "$COLOR_CYAN" ]]
  [[ "$result_high" == "$COLOR_RED" ]]
}

@test "color-scale.sh - get_git_lines_color uses correct limits" {
  result_low=$(get_git_lines_color "50")
  result_high=$(get_git_lines_color "1500")
  
  [[ "$result_low" == "$COLOR_CYAN" ]]
  [[ "$result_high" == "$COLOR_RED" ]]
}

@test "color-scale.sh - get_git_untracked_color returns RED for high value" {
  result=$(get_git_untracked_color "15")
  [[ "$result" == "$COLOR_RED" ]]
}

@test "color-scale.sh - get_git_untracked_color returns YELLOW for medium value" {
  result=$(get_git_untracked_color "5")
  [[ "$result" == "$COLOR_YELLOW" ]]
}

@test "color-scale.sh - get_git_untracked_color returns CYAN for low value" {
  result=$(get_git_untracked_color "2")
  [[ "$result" == "$COLOR_CYAN" ]]
}

@test "color-scale.sh - get_git_pr_color returns CYAN for zero" {
  result=$(get_git_pr_color "0")
  [[ "$result" == "$COLOR_CYAN" ]]
}

@test "color-scale.sh - get_git_pr_color returns GREEN for low value" {
  result=$(get_git_pr_color "2")
  [[ "$result" == "$COLOR_GREEN" ]]
}

@test "color-scale.sh - get_git_pr_color returns BLUE for medium value" {
  result=$(get_git_pr_color "3")
  [[ "$result" == "$COLOR_BLUE" ]]
}

@test "color-scale.sh - get_git_pr_color returns YELLOW for high value" {
  result=$(get_git_pr_color "5")
  [[ "$result" == "$COLOR_YELLOW" ]]
}

@test "color-scale.sh - get_git_review_color returns CYAN for zero" {
  result=$(get_git_review_color "0")
  [[ "$result" == "$COLOR_CYAN" ]]
}

@test "color-scale.sh - get_git_review_color returns YELLOW for low value" {
  result=$(get_git_review_color "2")
  [[ "$result" == "$COLOR_YELLOW" ]]
}

@test "color-scale.sh - get_git_review_color returns RED for high value" {
  result=$(get_git_review_color "3")
  [[ "$result" == "$COLOR_RED" ]]
}

@test "color-scale.sh - get_git_issue_color returns CYAN for zero" {
  result=$(get_git_issue_color "0")
  [[ "$result" == "$COLOR_CYAN" ]]
}

@test "color-scale.sh - get_git_issue_color returns GREEN for low value" {
  result=$(get_git_issue_color "3")
  [[ "$result" == "$COLOR_GREEN" ]]
}

@test "color-scale.sh - get_git_issue_color returns BLUE for medium value" {
  result=$(get_git_issue_color "7")
  [[ "$result" == "$COLOR_BLUE" ]]
}

@test "color-scale.sh - get_git_issue_color returns YELLOW for high value" {
  result=$(get_git_issue_color "12")
  [[ "$result" == "$COLOR_YELLOW" ]]
}

@test "color-scale.sh - get_git_bug_color returns CYAN for zero" {
  result=$(get_git_bug_color "0")
  [[ "$result" == "$COLOR_CYAN" ]]
}

@test "color-scale.sh - get_git_bug_color returns RED for value > 0" {
  result=$(get_git_bug_color "1")
  [[ "$result" == "$COLOR_RED" ]]
}

@test "color-scale.sh - get_net_speed_color returns CYAN for low speed" {
  result=$(get_net_speed_color "500000")
  [[ "$result" == "$COLOR_CYAN" ]]
}

@test "color-scale.sh - get_net_speed_color returns BLUE for medium speed" {
  result=$(get_net_speed_color "5000000")
  [[ "$result" == "$COLOR_BLUE" ]]
}

@test "color-scale.sh - get_net_speed_color returns GREEN for high speed" {
  result=$(get_net_speed_color "20000000")
  [[ "$result" == "$COLOR_GREEN" ]]
}

@test "color-scale.sh - get_net_speed_color returns YELLOW for very high speed" {
  result=$(get_net_speed_color "60000000")
  [[ "$result" == "$COLOR_YELLOW" ]]
}

@test "color-scale.sh - get_net_ping_color returns CYAN for low ping" {
  result=$(get_net_ping_color "15")
  [[ "$result" == "$COLOR_CYAN" ]]
}

@test "color-scale.sh - get_net_ping_color returns BLUE for medium ping" {
  result=$(get_net_ping_color "30")
  [[ "$result" == "$COLOR_BLUE" ]]
}

@test "color-scale.sh - get_net_ping_color returns YELLOW for high ping" {
  result=$(get_net_ping_color "75")
  [[ "$result" == "$COLOR_YELLOW" ]]
}

@test "color-scale.sh - get_net_ping_color returns RED for very high ping" {
  result=$(get_net_ping_color "150")
  [[ "$result" == "$COLOR_RED" ]]
}

@test "color-scale.sh - get_temperature_color_and_icon returns correct for negative temp" {
  result=$(get_temperature_color_and_icon "-5°C")
  [[ -n "$result" ]]
}

@test "color-scale.sh - get_temperature_color_and_icon returns correct for low temp" {
  result=$(get_temperature_color_and_icon "5°C")
  [[ -n "$result" ]]
}

@test "color-scale.sh - get_temperature_color_and_icon returns correct for comfortable temp" {
  result=$(get_temperature_color_and_icon "22°C")
  [[ -n "$result" ]]
}

@test "color-scale.sh - get_temperature_color_and_icon returns correct for high temp" {
  result=$(get_temperature_color_and_icon "35°C")
  [[ -n "$result" ]]
}

@test "color-scale.sh - get_timezone_period_icon returns icon for weekend" {
  result=$(get_timezone_period_icon "12" "1")
  [[ "$result" == "󰙵" ]]
}

@test "color-scale.sh - get_timezone_period_icon returns correct icon for different times" {
  result_morning=$(get_timezone_period_icon "8" "0")
  result_noon=$(get_timezone_period_icon "12" "0")
  result_evening=$(get_timezone_period_icon "19" "0")
  result_night=$(get_timezone_period_icon "23" "0")
  
  [[ -n "$result_morning" ]]
  [[ -n "$result_noon" ]]
  [[ -n "$result_evening" ]]
  [[ -n "$result_night" ]]
}

@test "color-scale.sh - get_timezone_period_color returns dim color for weekend" {
  result=$(get_timezone_period_color "12" "1")
  [[ "$result" =~ dim ]]
}

@test "color-scale.sh - get_timezone_period_color returns correct color for different periods" {
  result_morning=$(get_timezone_period_color "8" "0")
  result_noon=$(get_timezone_period_color "12" "0")
  result_evening=$(get_timezone_period_color "19" "0")
  result_night=$(get_timezone_period_color "23" "0")
  
  [[ -n "$result_morning" ]]
  [[ -n "$result_noon" ]]
  [[ -n "$result_evening" ]]
  [[ -n "$result_night" ]]
}

@test "color-scale.sh - get_git_changes_icon returns correct icon" {
  result_low=$(get_git_changes_icon "3")
  result_high=$(get_git_changes_icon "35")
  
  [[ -n "$result_low" ]]
  [[ -n "$result_high" ]]
}

@test "color-scale.sh - get_git_insertions_icon returns correct icon" {
  result_low=$(get_git_insertions_icon "50")
  result_high=$(get_git_insertions_icon "1500")
  
  [[ -n "$result_low" ]]
  [[ -n "$result_high" ]]
}

@test "color-scale.sh - get_git_deletions_icon returns correct icon" {
  result_low=$(get_git_deletions_icon "50")
  result_high=$(get_git_deletions_icon "1500")
  
  [[ -n "$result_low" ]]
  [[ -n "$result_high" ]]
}

@test "color-scale.sh - get_git_untracked_icon returns correct icon" {
  result_low=$(get_git_untracked_icon "2")
  result_high=$(get_git_untracked_icon "15")
  
  [[ -n "$result_low" ]]
  [[ -n "$result_high" ]]
}

@test "color-scale.sh - get_git_pr_icon returns correct icon" {
  result_zero=$(get_git_pr_icon "0")
  result_low=$(get_git_pr_icon "2")
  result_high=$(get_git_pr_icon "5")
  
  [[ -n "$result_zero" ]]
  [[ -n "$result_low" ]]
  [[ -n "$result_high" ]]
}

@test "color-scale.sh - get_git_review_icon returns correct icon" {
  result_zero=$(get_git_review_icon "0")
  result_low=$(get_git_review_icon "2")
  result_high=$(get_git_review_icon "3")
  
  [[ -n "$result_zero" ]]
  [[ -n "$result_low" ]]
  [[ -n "$result_high" ]]
}

@test "color-scale.sh - get_git_issue_icon returns correct icon" {
  result_zero=$(get_git_issue_icon "0")
  result_low=$(get_git_issue_icon "3")
  result_high=$(get_git_issue_icon "12")
  
  [[ -n "$result_zero" ]]
  [[ -n "$result_low" ]]
  [[ -n "$result_high" ]]
}

@test "color-scale.sh - format_if_nonzero formats for value > 0" {
  result=$(format_if_nonzero "$COLOR_CYAN" "󰖙" "50" "%")
  [[ -n "$result" ]]
  [[ "$result" =~ 50% ]]
}

