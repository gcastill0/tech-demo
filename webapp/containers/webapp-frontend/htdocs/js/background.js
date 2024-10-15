window.onload = function () {

    /* Create isometric matrix map */

    const cx = 50
    const cy = 50
    const html = document.documentElement
    const body = document.body
    const view_port_width = Math.max(html.clientWidth, 
        html.scrollWidth, html.offsetWidth, 
        body.scrollWidth, body.offsetWidth);
        
    const view_port_height = Math.max(html.clientHeight, 
        html.scrollHeight, html.offsetHeight, 
        body.scrollHeight, body.offsetHeight);


    console.log(view_port_height)

    const max_cols = Math.floor(view_port_width / cx) + 1
    const max_rows = Math.floor(view_port_height / cy) + 1  

    console.log("cols", max_cols, "rows", max_rows)

    var matrix = []

    console.log(view_port_width, view_port_height)


    for (var row = 2; row <= max_rows; row++) {
        var points = []

        var y = row * cy

        for (var col = 0; col <= max_cols; col++) {
            var x = (col * cx)
            if (row % 2 == 0) {
                x = (col * cx) - cx / 2
            }
    
            points.push({ x, y })
        }

        matrix.push(points)
    }

    console.log(matrix.length)
    console.log(matrix)

    /* Create SVG pattern */

    const bg_svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
    bg_svg.setAttribute('fill', 'none');
    bg_svg.setAttribute('viewBox', '0 0 ' + view_port_width + ' ' + view_port_height);
    bg_svg.setAttribute('stroke', 'black');
    bg_svg.classList.add('post-icon');

    /* 
       Add circles in a pseudo random distribution. It really just matches the
       isometric map points and we're picking random points in each row. 
    */

    matrix.forEach(addSVG_circle)

    function addSVG_circle(values) {
        for (var i = 0; i < Math.floor( 0.75 * values.length) ; i++) {
            const randy = Math.floor(Math.random() * values.length * 1.2)

            if (randy >= values.length) continue

            const radius = Math.floor(Math.random() * 5)
            const opacity = Math.random() / 3
            const colour = (Math.floor(Math.random() * 10) % 2 == 0) ? "#f2f2f2" : "#e0e0e0"

            const group = document.createElementNS("http://www.w3.org/2000/svg", "g")
            const circle = document.createElementNS("http://www.w3.org/2000/svg", "circle")

            circle.setAttribute("cx", values[randy].x)
            circle.setAttribute("cy", values[randy].y)
            circle.setAttribute("r", radius)
            circle.setAttribute("stroke", "none")
            circle.setAttribute("fill", colour)
            circle.setAttribute("opacity", opacity)

            group.appendChild(circle)

            const diceroll = Math.floor(Math.random() * 5)

            if (diceroll % 2 == 1) {
                const svgAnimate = document.createElementNS("http://www.w3.org/2000/svg", "animate")
                const duration = Math.floor(Math.random() * 30) + 1
                svgAnimate.setAttribute("attributeName", "opacity")
                svgAnimate.setAttribute("dur", duration + "s")
                svgAnimate.setAttribute("keyTimes", "0;0.32;0.35;0.8;0.9;1")
                svgAnimate.setAttribute("values", "0;0.5;1;1;0.5;0")
                svgAnimate.setAttribute("repeatCount", "indefinite")
                group.appendChild(svgAnimate)
            }

            bg_svg.appendChild(group)
        }
    }

    /* 
        Finish with SVG pattern using this animation template.
        This allows the dots to flash in and out of view for 
        a little while. 

        Need to check for requirement of minimal animation from
        the user, but the effect is very subtle and nuanced.

        <animate 
            attributeName="opacity" 
            dur="120s" 
            keyTimes="0;0.32;0.35;0.8;0.9;1"
            values="0;0;1;1;1;0" 
            repeatCount="indefinite" />
    */

    /* Prepare base64 payload */
    const s = new XMLSerializer();
    const str = s.serializeToString(bg_svg);
    const bg_svg64 = window.btoa(str)

    /* Set background properties in body */
    body.style.backgroundImage = "url('data:image/svg+xml;base64," + bg_svg64 + "')"
    body.style.backgroundRepeat = "repeat"
    body.style.backgroundSize = "cover"
}
