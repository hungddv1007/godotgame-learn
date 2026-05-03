shader_type spatial;

// Biến điều chỉnh độ to nhỏ của ô caro
uniform float grid_scale = 10.0;

// Chọn màu trực tiếp từ Inspector
uniform vec3 color1 : source_color = vec3(0.2, 0.6, 0.2); // Màu xanh nhạt
uniform vec3 color2 : source_color = vec3(0.1, 0.3, 0.1); // Màu xanh đậm

void fragment() {
    // Nhân tọa độ UV với kích thước lưới
    vec2 grid_uv = UV * grid_scale;
    
    // Thuật toán tạo ô caro chẵn lẻ
    float checker = mod(floor(grid_uv.x) + floor(grid_uv.y), 2.0);
    
    // Hiển thị màu xen kẽ dựa trên kết quả tính toán
    ALBEDO = mix(color1, color2, checker);
}