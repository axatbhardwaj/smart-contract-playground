const axios = require('axios');

async function test() {
    try {
        const apiResponse = await axios.get('https://animechan.io/api/v1/quotes/random');
        if (apiResponse.error) {
            console.error(apiResponse.error);
            throw new Error('Request failed');
        }
        const data = apiResponse.data.data;
        console.log(data);
        const quote = data.content;
        const anime = data.anime.name;
        const character = data.character.name;
        const result = JSON.stringify({ quote, anime, character });
        console.log(result);
    } catch (error) {
        console.error(error);
    }
}

test();
// sample response
// { "status": "success", "data": { "content": "Don't start a fight that you can't finish.", "anime": { "id": 229, "name": "One Piece" }, "character": { "id": 1113, "name": "Sanji" } } }