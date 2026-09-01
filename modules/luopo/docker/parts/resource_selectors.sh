#!/usr/bin/env bash
set -euo pipefail

# Numbered Docker resource selectors shared by container, image, network, and volume actions.

DOCKER_SELECTED_VALUE=""
DOCKER_SELECTED_LABEL=""

docker_choose_resource() {
  local title="$1"
  local empty_message="$2"
  shift 2

  local output row value label choice index
  local -a values=()
  local -a labels=()
  DOCKER_SELECTED_VALUE=""
  DOCKER_SELECTED_LABEL=""

  if ! output="$("$@")"; then
    echo "Docker 资源列表读取失败"
    return 1
  fi

  while IFS= read -r row; do
    [[ -n "$row" ]] || continue
    IFS=$'\t' read -r value label <<<"$row"
    [[ -n "$value" && -n "$label" ]] || continue
    values+=("$value")
    labels+=("$label")
  done <<<"$output"

  if ((${#values[@]} == 0)); then
    echo "$empty_message"
    return 1
  fi

  echo "========================================"
  echo "$title"
  echo "========================================"
  for index in "${!values[@]}"; do
    menu_item "$((index + 1))" "${labels[$index]}"
  done
  echo "----------------------------------------"
  menu_item "0" "取消返回"
  echo "========================================"
  read -r -p "请输入编号: " choice

  if [[ "$choice" == "0" ]]; then
    echo "已取消"
    return 1
  fi
  if [[ ! "$choice" =~ ^[0-9]+$ ]] || ((choice < 1 || choice > ${#values[@]})); then
    echo "无效编号"
    return 1
  fi

  DOCKER_SELECTED_VALUE="${values[$((choice - 1))]}"
  DOCKER_SELECTED_LABEL="${labels[$((choice - 1))]}"
}

docker_confirm_action() {
  local prompt="$1"
  local answer
  read -r -p "${prompt} (Y/N): " answer
  if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    return 0
  fi
  echo "已取消"
  return 1
}

docker_container_selection_rows() {
  local scope="${1:-all}"
  local -a args=(ps)
  if [[ "$scope" == "all" ]]; then
    args+=(-a)
  fi
  args+=(--format '{{.ID}}\t{{.Names}} [{{.ID}}] | {{.Status}} | {{.Image}}')
  docker "${args[@]}"
}

docker_image_selection_rows() {
  local output repository tag image_id size target label
  if ! output="$(docker image ls --format '{{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}')"; then
    return 1
  fi

  while IFS=$'\t' read -r repository tag image_id size; do
    [[ -n "$image_id" ]] || continue
    if [[ "$repository" == "<none>" || "$tag" == "<none>" ]]; then
      target="$image_id"
      label="<none> [${image_id}] | ${size}"
    else
      target="${repository}:${tag}"
      label="${target} [${image_id}] | ${size}"
    fi
    printf '%s\t%s\n' "$target" "$label"
  done <<<"$output"
}

docker_network_selection_rows() {
  local mode="${1:-all}"
  local output network_id network_name driver scope
  if ! output="$(docker network ls --format '{{.ID}}\t{{.Name}}\t{{.Driver}}\t{{.Scope}}')"; then
    return 1
  fi

  while IFS=$'\t' read -r network_id network_name driver scope; do
    [[ -n "$network_name" ]] || continue
    if [[ "$mode" == "removable" && ("$network_name" == "bridge" || "$network_name" == "host" || "$network_name" == "none") ]]; then
      continue
    fi
    printf '%s\t%s [%s] | %s | %s\n' "$network_name" "$network_name" "$network_id" "$driver" "$scope"
  done <<<"$output"
}

docker_network_container_selection_rows() {
  local network_name="$1"
  docker network inspect --format '{{range $id, $container := .Containers}}{{$container.Name}}{{"\t"}}{{$container.Name}} [{{printf "%.12s" $id}}]{{"\n"}}{{end}}' "$network_name"
}

docker_volume_selection_rows() {
  docker volume ls --format '{{.Name}}\t{{.Name}} | {{.Driver}}'
}
