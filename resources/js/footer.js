const footerHTML = `<footer style="padding: 1em 0; margin: 0; width: 100%; display: flex; justify-content: center;"><div style="width: 70%; text-align: center; margin: 0; padding: 0;"><img alt="Creative Commons License" style="border-width:0" src="/resources/images/cc.png" height="18px" /> This work is licensed under a <a rel="license" href="https://creativecommons.org/licenses/by-nc/4.0/" style="color:#666;">Creative Commons Attribution-NonCommercial 4.0 license (CC BY-NC 4.0)</a>.<br />Copyright © 2011 Beth Mardutho: The Syriac Institute.</div></footer>`;

document.addEventListener('DOMContentLoaded', function() {
    document.body.insertAdjacentHTML('beforeend', footerHTML);
});
