import env from './env_variables.json' with {type: 'json'}

const PREFIX = env.PREFIX
const POSTFIX = env.POSTFIX

console.log(PREFIX, POSTFIX)

const main_div = document.createElement("main")
const grid_container = document.createElement("div")

const interactive_bg = document.createElement("div")
interactive_bg.classList.add("interactive-background")

grid_container.classList.add("grid-container")
grid_container.loading = "lazy"

document.body.appendChild(interactive_bg)
document.body.appendChild(main_div)
main_div.appendChild(grid_container)

const overlay_container = document.querySelector(".overlay-container")
const overlay_card = document.querySelector(".overlay-card")
const overlay_card_legend = document.createElement("div")

overlay_card_legend.classList.add("overlay-card-legend") 

// Fetch the file URLs from the backend API
fetch('/api')  // Replace with the actual backend URL
    .then(response => response.json())
    .then(images_payload => {
        images_payload.forEach(image_name => {
            const grid_element = document.createElement("div")
            const grid_image = document.createElement("img")
            const grid_title = document.createElement("div")
            
            grid_image.src = "http://" + PREFIX + "-app-data-" + POSTFIX + ".s3.amazonaws.com/thumbs/" + image_name["filename"] + ".png"
            grid_image.loading = "lazy"
        
            grid_title.innerHTML = image_name["bot_name"]
            grid_title.classList.add("grid-title")
        
            grid_element.classList.add("grid-item")
        
            grid_element.appendChild(grid_image)    
            grid_element.appendChild(grid_title)
        
            grid_element.addEventListener('click', () => {
                const overlay_image = document.createElement("img")
                overlay_card_legend.innerHTML = ''
        
                overlay_image.src = "http://" + PREFIX + "-app-data-" + POSTFIX + ".s3.amazonaws.com/images/" + image_name["filename"] + ".png"
                overlay_image.loading = "lazy"
                
                overlay_card_legend.innerHTML = `<p>${image_name["bot_story"]}<p>`
                
                overlay_card.appendChild(overlay_image)
                overlay_card.appendChild(overlay_card_legend)
        
                overlay_container.style.display = "flex"
            })
            grid_container.appendChild(grid_element)
        
        })
        
    })
    .catch(error => console.error('Error fetching file data:', error));

overlay_container.addEventListener('click', () => { 
    overlay_card.removeChild(overlay_card.firstChild)
    overlay_container.style.display = "none"    
})
