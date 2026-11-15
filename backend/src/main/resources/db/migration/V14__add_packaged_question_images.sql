-- Packaged illustrations: preserve V12 revisions; attach 22 images in new revision 2.
-- SAT_MATH:15ce8207 remains absent. Its PNG is packaged but deliberately unbound.
ALTER TABLE questions ADD COLUMN image_key varchar(255);

CREATE TEMPORARY TABLE question_image_seed ON COMMIT DROP AS
SELECT * FROM jsonb_to_recordset($question_images$
[
  {
    "external_key": "SAT_MATH:124bc42b",
    "image_key": "SAT_MATH/124bc42b/692372baff22ee6a8bcc4c0c985ab7c0d351366562ddfc8aa917996d4f701dc4.png",
    "new_id": "88d09e60-524d-51ff-b889-bfc7982194c6",
    "expected": {
      "id": "55e54495-b4d5-573a-8909-078ca20d818c",
      "external_key": "SAT_MATH:124bc42b",
      "discipline_code": "SAT_MATH",
      "topic_code": "GEOMETRY_AREA_VOLUME",
      "topic_name": "Geometry and Trigonometry / Area and volume",
      "difficulty": "EASY",
      "prompt": "Rectangle $ABCD$ shown has a length of 7 units and a width of 2 units. What is the area, in square units, of rectangle $ABCD$?",
      "options": [
        {
          "id": "4cc9b820-b851-39a1-9f94-03a2d62ca6ac",
          "key": "A",
          "text": "5"
        },
        {
          "id": "93f9a884-a907-3ca0-956f-b7f3e99f88c0",
          "key": "B",
          "text": "9"
        },
        {
          "id": "009e051c-f911-3825-b5d0-bb625e884454",
          "key": "C",
          "text": "14"
        },
        {
          "id": "2f74fed8-5cf1-31fa-95da-26b7952aaed6",
          "key": "D",
          "text": "28"
        }
      ],
      "correct_option_id": "009e051c-f911-3825-b5d0-bb625e884454",
      "explanation": "Choice C is correct. The area $A$ of a rectangle is the product of its length and width:\n$$A = \\ell w = 7 \\times 2 = 14\\text{ square units}$$",
      "content_version": 1,
      "active": true,
      "deleted": false
    }
  },
  {
    "external_key": "SAT_MATH:1ee962ec",
    "image_key": "SAT_MATH/1ee962ec/744a3fb8274bfe60c4cb51a5cd14d26b7aecb6d62980c24c95f60639e68bfaca.png",
    "new_id": "b6af6bd2-82cd-5cdc-b85d-d9d82886665e",
    "expected": {
      "id": "e71dc91e-337c-5aa7-a1e8-ebffb667ab6c",
      "external_key": "SAT_MATH:1ee962ec",
      "discipline_code": "SAT_MATH",
      "topic_code": "ADVANCED_NONLINEAR_FUNCTIONS",
      "topic_name": "Advanced Math / Nonlinear functions",
      "difficulty": "EASY",
      "prompt": "Scientists recorded data about the ocean water levels at a certain location over a period of 6 hours. The graph shown models the data, where $y = 0$ represents sea level. The graph is a parabola opening upward with vertex at $(3, -12)$ that intersects the $x$-axis at $(0, 0)$ and $(6, 0)$. Which table gives values of $x$ and their corresponding values of $y$ based on the model?",
      "options": [
        {
          "id": "dfffc2ae-82f4-33f3-95bf-36712a071c0f",
          "key": "A",
          "text": "| $x$ | $y$ |\n  | :---: | :---: |\n  | 0 | $-12$ |\n  | 0 | 3 |\n  | 3 | 6 |"
        },
        {
          "id": "5ff10220-a960-32c9-870b-f1e73d72d8fb",
          "key": "B",
          "text": "| $x$ | $y$ |\n  | :---: | :---: |\n  | 0 | 0 |\n  | 3 | 12 |\n  | 0 | $-6$ |"
        },
        {
          "id": "3fdfa472-20b6-3c97-9c89-cc5bb05b861f",
          "key": "C",
          "text": "| $x$ | $y$ |\n  | :---: | :---: |\n  | 0 | 0 |\n  | 3 | $-12$ |\n  | 6 | 0 |"
        },
        {
          "id": "16e043e0-abad-3d5a-8561-d27af49e19e4",
          "key": "D",
          "text": "| $x$ | $y$ |\n  | :---: | :---: |\n  | 0 | 0 |\n  | 12 | 3 |\n  | $-6$ | 0 |"
        }
      ],
      "correct_option_id": "3fdfa472-20b6-3c97-9c89-cc5bb05b861f",
      "explanation": "Choice C is correct. The graph represents points $(x, y)$ where $x$ is elapsed time in hours and $y$ is ocean water level in feet. The graph starts at $(0, 0)$, reaches its minimum at the vertex $(3, -12)$, and returns to sea level at $(6, 0)$. These three points match the entries in table C.",
      "content_version": 1,
      "active": true,
      "deleted": false
    }
  },
  {
    "external_key": "SAT_MATH:4a2264b3",
    "image_key": "SAT_MATH/4a2264b3/c1568785c3d7777d34f2afa0cc1198b6975084c0b8349fdb627e8c63d1971b20.png",
    "new_id": "697e462c-fe14-51e3-879b-31d049123b6c",
    "expected": {
      "id": "960784c2-07d1-5b73-a707-22d18b2e67d7",
      "external_key": "SAT_MATH:4a2264b3",
      "discipline_code": "SAT_MATH",
      "topic_code": "DATA_TWO_VARIABLES",
      "topic_name": "Problem-Solving and Data Analysis / Two-variable data: Models and scatterplots",
      "difficulty": "EASY",
      "prompt": "The line graph shows the percent of cars for sale at a used car lot on a given day by model year (2010 to 2019). The plotted values are approximately:\n- 2010 to 2012: $12\\%$\n- 2013: $8\\%$\n- 2014: $4\\%$\n- 2015: $9\\%$\n- 2016 to 2017: $10\\%$\n- 2018 to 2019: $11\\%$\n\nFor what model year is the percent of cars for sale the smallest?",
      "options": [
        {
          "id": "08ebd493-18fd-37d5-a1ad-1d6f95f57fb0",
          "key": "A",
          "text": "2012"
        },
        {
          "id": "2a53e400-4a60-3e22-9d4f-419006100b15",
          "key": "B",
          "text": "2013"
        },
        {
          "id": "0815b853-98fe-38dd-b1c1-f3abbbe1c298",
          "key": "C",
          "text": "2014"
        },
        {
          "id": "4df42898-d61f-35f3-a615-19dcff930357",
          "key": "D",
          "text": "2015"
        }
      ],
      "correct_option_id": "0815b853-98fe-38dd-b1c1-f3abbbe1c298",
      "explanation": "Choice C is correct. The vertical axis represents the percent of cars for sale. The lowest point on the graph reaches approximately $4\\%$, which corresponds to the model year 2014 on the horizontal axis.",
      "content_version": 1,
      "active": true,
      "deleted": false
    }
  },
  {
    "external_key": "SAT_MATH:744ee7d7",
    "image_key": "SAT_MATH/744ee7d7/e24cf660ca60a721b3135156c5ec0bad88f1e06698f60022c14f25b4942f3751.png",
    "new_id": "e3d5241b-80ba-5475-8d8b-e1eb93a463b4",
    "expected": {
      "id": "8f79ec93-610c-5343-99a1-bcd794c7d1be",
      "external_key": "SAT_MATH:744ee7d7",
      "discipline_code": "SAT_MATH",
      "topic_code": "ALGEBRA_LINEAR_INEQUALITIES",
      "topic_name": "Algebra / Linear inequalities in one or two variables",
      "difficulty": "EASY",
      "prompt": "The shaded region shown in the graph in the $xy$-plane has a solid horizontal boundary line passing through $(0, 36)$ and $(-15, 36)$, with shading covering all points on and above this line. The shaded region represents all the solutions to which inequality?",
      "options": [
        {
          "id": "61a5bb4c-8e52-34b6-a8fe-117e2892b22f",
          "key": "A",
          "text": "$x \\le 36$"
        },
        {
          "id": "f08e7840-c605-3fa8-b5e6-6bf8fbece80c",
          "key": "B",
          "text": "$x \\ge 36$"
        },
        {
          "id": "d4403949-7077-3a7f-bfc1-94eae47da5b7",
          "key": "C",
          "text": "$y \\le 36$"
        },
        {
          "id": "c599a43c-4929-399b-b4af-31647fc9a028",
          "key": "D",
          "text": "$y \\ge 36$"
        }
      ],
      "correct_option_id": "c599a43c-4929-399b-b4af-31647fc9a028",
      "explanation": "Choice D is correct. A horizontal line in the $xy$-plane has the equation $y = b$. Since the boundary line passes through $(0, 36)$, its equation is $y = 36$. The shaded region includes all points with $y$-coordinates greater than or equal to 36, which is represented by the inequality $y \\ge 36$.",
      "content_version": 1,
      "active": true,
      "deleted": false
    }
  },
  {
    "external_key": "SAT_MATH:b0c5ece5",
    "image_key": "SAT_MATH/b0c5ece5/6ce23a2c7bac99a2a60491beb967f348c5b29c90c415ab889d455c60b6814689.png",
    "new_id": "2b5dc962-4f1d-53af-8785-ad0cbb721bfa",
    "expected": {
      "id": "5a5fc29c-4f58-5671-9a6a-d7e3084c51e1",
      "external_key": "SAT_MATH:b0c5ece5",
      "discipline_code": "SAT_MATH",
      "topic_code": "GEOMETRY_RIGHT_TRIANGLES_TRIGONOMETRY",
      "topic_name": "Geometry and Trigonometry / Right triangles and trigonometry",
      "difficulty": "EASY",
      "prompt": "A right triangle has legs with lengths 4 and $b$ and a hypotenuse of length 19. Which equation shows the relationship between the side lengths of the given triangle?",
      "options": [
        {
          "id": "18c06f87-e2d7-3286-b8bc-804d75da0b8e",
          "key": "A",
          "text": "$4b = 19$"
        },
        {
          "id": "5643e2c2-5407-34e3-9fb3-9e033c8672d0",
          "key": "B",
          "text": "$4 + b = 19$"
        },
        {
          "id": "0aefafe2-0b70-3723-9b1a-a175ed7dda88",
          "key": "C",
          "text": "$4^2 + b^2 = 19^2$"
        },
        {
          "id": "283be9e8-8eed-334a-b855-7031900ec08a",
          "key": "D",
          "text": "$4^2 - b^2 = 19^2$"
        }
      ],
      "correct_option_id": "0aefafe2-0b70-3723-9b1a-a175ed7dda88",
      "explanation": "Choice C is correct. By the Pythagorean theorem, the sum of the squares of the lengths of the two legs equals the square of the length of the hypotenuse:\n$$a^2 + b^2 = c^2 \\implies 4^2 + b^2 = 19^2$$",
      "content_version": 1,
      "active": true,
      "deleted": false
    }
  },
  {
    "external_key": "SAT_MATH:c24e1bda",
    "image_key": "SAT_MATH/c24e1bda/46c9b856ae8ecfb87de012fc32f0bcae4a1bc086bd9483adf5a494d0bcdab115.png",
    "new_id": "1e7e312d-1b6f-5181-a596-15b077d3411c",
    "expected": {
      "id": "3b5f8998-b856-5151-8b58-8062c29667c9",
      "external_key": "SAT_MATH:c24e1bda",
      "discipline_code": "SAT_MATH",
      "topic_code": "GEOMETRY_LINES_ANGLES_TRIANGLES",
      "topic_name": "Geometry and Trigonometry / Lines, angles, and triangles",
      "difficulty": "EASY",
      "prompt": "In the figure, line $m$ is parallel to line $n$. Transversal $t$ intersects line $m$ and line $n$, forming corresponding angles with measures $134^\\circ$ and $w^\\circ$. What is the value of $w$?",
      "options": [
        {
          "id": "dee6c169-cae4-3fd8-92f4-09b5243d7eef",
          "key": "A",
          "text": "13"
        },
        {
          "id": "5cfc4ea3-f1d4-34be-811d-df2df66110ce",
          "key": "B",
          "text": "34"
        },
        {
          "id": "b2d859b9-8f8a-3651-918f-86f2aa832ab0",
          "key": "C",
          "text": "66"
        },
        {
          "id": "118cd011-2d56-3cca-beb8-e38bc8f0d960",
          "key": "D",
          "text": "134"
        }
      ],
      "correct_option_id": "118cd011-2d56-3cca-beb8-e38bc8f0d960",
      "explanation": "Choice D is correct. When two parallel lines are cut by a transversal, corresponding angles are congruent and have equal measures. Since the angle of $134^\\circ$ and the angle of $w^\\circ$ are corresponding angles:\n$$w = 134$$",
      "content_version": 1,
      "active": true,
      "deleted": false
    }
  },
  {
    "external_key": "SAT_MATH:e6f2ace7",
    "image_key": "SAT_MATH/e6f2ace7/9edb1e89b01d0d3731c34c8640c8712f70cb31fe7aeead7818a7fb6bea13fbbc.png",
    "new_id": "a7362efe-06b0-50f9-a415-82b141e21712",
    "expected": {
      "id": "fd54386d-a831-5119-8ceb-f15b4dad2721",
      "external_key": "SAT_MATH:e6f2ace7",
      "discipline_code": "SAT_MATH",
      "topic_code": "GEOMETRY_RIGHT_TRIANGLES_TRIGONOMETRY",
      "topic_name": "Geometry and Trigonometry / Right triangles and trigonometry",
      "difficulty": "EASY",
      "prompt": "The lengths of the legs of a right triangle are 3 and 7. Which of the following is closest to the length of the triangle’s hypotenuse?",
      "options": [
        {
          "id": "fe027c0c-d3e2-3c7c-8480-e86e7c4faed8",
          "key": "A",
          "text": "3.2"
        },
        {
          "id": "d01be096-22d6-347b-a850-b3bbf7270d26",
          "key": "B",
          "text": "5"
        },
        {
          "id": "b3053de7-a828-36ad-93e6-e62e53d75f69",
          "key": "C",
          "text": "7.6"
        },
        {
          "id": "b6eef288-e7c8-3eb3-b4dc-61444cef3dc0",
          "key": "D",
          "text": "20"
        }
      ],
      "correct_option_id": "b3053de7-a828-36ad-93e6-e62e53d75f69",
      "explanation": "Choice C is correct. According to the Pythagorean theorem, for a right triangle with legs $a$ and $b$ and hypotenuse $c$:\n$$a^2 + b^2 = c^2$$\nSubstituting $a = 3$ and $b = 7$:\n$$3^2 + 7^2 = c^2 \\implies 9 + 49 = c^2 \\implies c^2 = 58 \\implies c = \\sqrt{58} \\approx 7.615$$\nAmong the choices, 7.6 is closest to the length of the hypotenuse.",
      "content_version": 1,
      "active": true,
      "deleted": false
    }
  },
  {
    "external_key": "SAT_MATH:2e8027b0",
    "image_key": "SAT_MATH/2e8027b0/f4fc07580c4892e5b9c031f1a18ab424bc55a628ce21c7980ea3db415e011341.png",
    "new_id": "0c076602-005c-5b5d-b895-58fe529a5cff",
    "expected": {
      "id": "573f2988-8420-53b9-bf83-d28aed1e0ff3",
      "external_key": "SAT_MATH:2e8027b0",
      "discipline_code": "SAT_MATH",
      "topic_code": "DATA_TWO_VARIABLES",
      "topic_name": "Problem-Solving and Data Analysis / Two-variable data: Models and scatterplots",
      "difficulty": "HARD",
      "prompt": "The scatterplot shows the relationship between two variables, $x$ and $y$, for data set E. A line of best fit is shown. Data set F is created by multiplying the $y$-coordinate of each data point from data set E by $3.9$. Which of the following could be an equation of a line of best fit for data set F?",
      "options": [
        {
          "id": "0ec1e232-2bcf-3036-bae0-51563e3f5f4b",
          "key": "A",
          "text": "$y = 46.8 + 5.9x$"
        },
        {
          "id": "0e287ccd-0a27-30a0-a67a-022a03cbbae4",
          "key": "B",
          "text": "$y = 46.8 + 1.5x$"
        },
        {
          "id": "13b491ad-59ca-3bfc-a6cd-c2dd48665c9f",
          "key": "C",
          "text": "$y = 12 + 5.9x$"
        },
        {
          "id": "992cd468-d60a-35f4-b284-cb9578f58b8c",
          "key": "D",
          "text": "$y = 12 + 1.5x$"
        }
      ],
      "correct_option_id": "0ec1e232-2bcf-3036-bae0-51563e3f5f4b",
      "explanation": "Choice A is correct. The line of best fit for data set E has a $y$-intercept at approximately $(0, 12)$ and passes through approximately $(12, 30)$. Its slope is:\n$$m_E \\approx \\frac{30 - 12}{12 - 0} = \\frac{18}{12} = 1.5$$\nThus the line of best fit for data set E is approximately $y = 12 + 1.5x$.\nSince each $y$-coordinate is multiplied by $3.9$ to create data set F, both the $y$-intercept and slope are scaled by $3.9$:\n$$\\text{New } y\\text{-intercept} = 12 \\times 3.9 = 46.8$$\n$$\\text{New slope} = 1.5 \\times 3.9 = 5.85 \\approx 5.9$$\nTherefore, an equation of a line of best fit for data set F is $y = 46.8 + 5.9x$.",
      "content_version": 1,
      "active": true,
      "deleted": false
    }
  },
  {
    "external_key": "SAT_MATH:3f5a3602",
    "image_key": "SAT_MATH/3f5a3602/224eefc655e44ddac7e07d499e9fad2ba90e28bd8db675e8cd15b31156b7a203.png",
    "new_id": "feda98d6-3cc3-5bf5-9a0f-9c34110a9974",
    "expected": {
      "id": "7ca33bbc-f5b0-5d70-965f-b08f44dc23dc",
      "external_key": "SAT_MATH:3f5a3602",
      "discipline_code": "SAT_MATH",
      "topic_code": "ALGEBRA_LINEAR_SYSTEMS",
      "topic_name": "Algebra / Systems of two linear equations in two variables",
      "difficulty": "HARD",
      "prompt": "What system of linear equations is represented by the lines shown in the $xy$-plane?\n*(The graph shows two lines: one passing through $(8, 0)$ and $(3, 4)$, and the other passing through $(8, 0)$ and $(3, 2)$).*",
      "options": [
        {
          "id": "31d928db-d563-3e00-95f6-a9f4e7531747",
          "key": "A",
          "text": "$8x + 4y = 32$, $-10x - 4y = -64$"
        },
        {
          "id": "26baefc4-86a9-35fe-af63-f6508f20dee5",
          "key": "B",
          "text": "$8x - 4y = 32$, $-10x + 4y = -64$"
        },
        {
          "id": "f176b6fe-f5e5-3be4-839e-71e4adfcb6cd",
          "key": "C",
          "text": "$4x - 10y = 32$, $-8x + 10y = -64$"
        },
        {
          "id": "fac487a0-53b3-37a2-a440-bc2ebec8d05a",
          "key": "D",
          "text": "$4x + 10y = 32$, $-8x - 10y = -64$"
        }
      ],
      "correct_option_id": "fac487a0-53b3-37a2-a440-bc2ebec8d05a",
      "explanation": "Choice D is correct. A line in the $xy$-plane that passes through the points $(x_1, y_1)$ and $(x_2, y_2)$ has slope $m = \\frac{y_2 - y_1}{x_2 - x_1}$, and can be defined by an equation of the form $y - y_1 = m(x - x_1)$.\n\nOne of the lines shown in the graph passes through the points $(8, 0)$ and $(3, 4)$. Substituting $8$ for $x_1$, $0$ for $y_1$, $3$ for $x_2$, and $4$ for $y_2$ yields $m = \\frac{4 - 0}{3 - 8} = -\\frac{4}{5}$.\nSubstituting $-\\frac{4}{5}$ for $m$, $8$ for $x_1$, and $0$ for $y_1$ yields $y - 0 = -\\frac{4}{5}(x - 8)$, which is equivalent to $y = -\\frac{4}{5}x + \\frac{32}{5}$. Adding $\\frac{4}{5}x$ to both sides yields $\\frac{4}{5}x + y = \\frac{32}{5}$. Multiplying both sides by $-10$ yields $-8x - 10y = -64$.\n\nSimilarly, the other line shown in the graph passes through the points $(8, 0)$ and $(3, 2)$. Substituting $8$ for $x_1$, $0$ for $y_1$, $3$ for $x_2$, and $2$ for $y_2$ yields $m = \\frac{2 - 0}{3 - 8} = -\\frac{2}{5}$.\nSubstituting $-\\frac{2}{5}$ for $m$, $8$ for $x_1$, and $0$ for $y_1$ yields $y - 0 = -\\frac{2}{5}(x - 8)$, which is equivalent to $y = -\\frac{2}{5}x + \\frac{16}{5}$. Adding $\\frac{2}{5}x$ to both sides yields $\\frac{2}{5}x + y = \\frac{16}{5}$. Multiplying both sides by $10$ yields $4x + 10y = 32$.\n\nSo, the system of linear equations represented by the lines shown is $4x + 10y = 32$ and $-8x - 10y = -64$.\n\nChoices A, B, and C are incorrect and may result from conceptual or calculation errors.",
      "content_version": 1,
      "active": true,
      "deleted": false
    }
  },
  {
    "external_key": "SAT_MATH:947a3cde",
    "image_key": "SAT_MATH/947a3cde/48e9d32aaa83d2d20df6edacb7db50e730a8b8a289bbc7dea3fd67e0176307a9.png",
    "new_id": "97b27afe-3124-5996-a829-d646bd844411",
    "expected": {
      "id": "a905d366-a31e-5c37-b702-344649987664",
      "external_key": "SAT_MATH:947a3cde",
      "discipline_code": "SAT_MATH",
      "topic_code": "GEOMETRY_LINES_ANGLES_TRIANGLES",
      "topic_name": "Geometry and Trigonometry / Lines, angles, and triangles",
      "difficulty": "HARD",
      "prompt": "In the figure, $\\overline{MQ}$ and $\\overline{NR}$ intersect at point $P$, $NP = QP$, and $MP = PR$. In triangle $NPQ$, the measure of angle $NQP$ is $70^\\circ$ and the measure of angle $MPN$ is $60^\\circ$. What is the measure, in degrees, of $\\angle QMR$? (Disregard the degree symbol when gridding your answer.)",
      "options": [
        {
          "id": "f8b18d20-dd3f-3bfc-a5ee-f262395a08af",
          "key": "A",
          "text": "15"
        },
        {
          "id": "40d6c6c7-4a5d-3254-a20f-0469e3091d4b",
          "key": "B",
          "text": "45"
        },
        {
          "id": "0d56b97f-8b89-363d-8e79-256eb57ec8f9",
          "key": "C",
          "text": "30"
        },
        {
          "id": "49147f1a-11b6-3c9b-8c74-a39b05f72188",
          "key": "D",
          "text": "60"
        }
      ],
      "correct_option_id": "0d56b97f-8b89-363d-8e79-256eb57ec8f9",
      "explanation": "The correct answer is 30. Angles $\\angle MPN$ and $\\angle QPR$ are vertical angles, so their measures are equal:\n$$m\\angle QPR = m\\angle MPN = 60^\\circ$$\nAngles $\\angle MPR$ and $\\angle QPR$ form a linear pair and are supplementary:\n$$m\\angle MPR + m\\angle QPR = 180^\\circ \\implies m\\angle MPR = 180^\\circ - 60^\\circ = 120^\\circ$$\nIn triangle $MPR$, it is given that $MP = PR$, so triangle $MPR$ is an isosceles triangle with base angles $\\angle PMR$ and $\\angle PRM$:\n$$m\\angle PMR = m\\angle PRM = \\frac{180^\\circ - 120^\\circ}{2} = \\frac{60^\\circ}{2} = 30^\\circ$$\nSince point $P$ lies on segment $\\overline{MQ}$, $\\angle QMR$ is the same angle as $\\angle PMR$. Therefore, the measure of $\\angle QMR$ is $30^\\circ$.",
      "content_version": 1,
      "active": true,
      "deleted": false
    }
  },
  {
    "external_key": "SAT_MATH:9b7a1b67",
    "image_key": "SAT_MATH/9b7a1b67/658e106802fe90534be96f056e54b7ee96cdd6135f7875eb7a3f15b644fda3fe.png",
    "new_id": "8da0fd30-d31a-5d47-8f91-afef4d33643f",
    "expected": {
      "id": "f7db1bf4-1a53-544e-9dab-c0d9ca7c661d",
      "external_key": "SAT_MATH:9b7a1b67",
      "discipline_code": "SAT_MATH",
      "topic_code": "ALGEBRA_LINEAR_SYSTEMS",
      "topic_name": "Algebra / Systems of two linear equations in two variables",
      "difficulty": "HARD",
      "prompt": "The graph of line $h$ is shown in the $xy$-plane (passing through $(-6, 0)$ and $(0, -9)$). Line $k$ (not shown) is defined by $sx + 48y = t$, where $s$ and $t$ are constants. If line $k$ is graphed in this $xy$-plane, the result is a graph of two linear equations. This system of two linear equations has no solution. Which of the following is NOT a possible value of $t$?",
      "options": [
        {
          "id": "42253f5f-1470-3152-abd4-213c2a955ba9",
          "key": "A",
          "text": "$-432$"
        },
        {
          "id": "030d48bc-793c-38e7-a8e5-32b418ae7362",
          "key": "B",
          "text": "$-9$"
        },
        {
          "id": "f87f0aa5-57f8-3f8a-9e7b-1855188d7980",
          "key": "C",
          "text": "$72$"
        },
        {
          "id": "9ba378a1-cc74-3a8e-b823-cce5c13ec670",
          "key": "D",
          "text": "$288$"
        }
      ],
      "correct_option_id": "42253f5f-1470-3152-abd4-213c2a955ba9",
      "explanation": "Choice A is correct. Since the system has no solution, line $h$ and line $k$ must be parallel with different $y$-intercepts.\nThe $y$-intercept of line $h$ is $(0, -9)$.\nFor line $k$, substituting $x = 0$ into $sx + 48y = t$ gives $48y = t \\implies y = \\frac{t}{48}$, so its $y$-intercept is $(0, \\frac{t}{48})$.\nSince the two lines cannot have the same $y$-intercept:\n$$\\frac{t}{48} \\neq -9 \\implies t \\neq -9(48) = -432$$\nThus, $-432$ is NOT a possible value of $t$.\n\nChoice B is incorrect because $t = -9$ gives $y$-intercept $-\\frac{9}{48} \\neq -9$, which is possible. Choices C and D give $y$-intercepts different from $-9$, so they are possible values of $t$.",
      "content_version": 1,
      "active": true,
      "deleted": false
    }
  },
  {
    "external_key": "SAT_MATH:d12bca0a",
    "image_key": "SAT_MATH/d12bca0a/12fa97ee7fc0db559a9ec602428bdc353f5ac3fa1d07adcb9affea56a11b3296.png",
    "new_id": "4ae49eb6-df6c-54e4-8d9a-65dc3e8373ab",
    "expected": {
      "id": "23867d47-5f56-53ed-b899-37329f456f24",
      "external_key": "SAT_MATH:d12bca0a",
      "discipline_code": "SAT_MATH",
      "topic_code": "GEOMETRY_CIRCLES",
      "topic_name": "Geometry and Trigonometry / Circles",
      "difficulty": "HARD",
      "prompt": "The circle shown has its center at $(0, 0)$ and passes through the points $(8, 0)$ and $(2, k)$, where $(2, k)$ lies in the first quadrant above the $x$-axis. What is the value of $k$?",
      "options": [
        {
          "id": "17368dbd-5950-336b-b773-71aab8ec2b9b",
          "key": "A",
          "text": "$6$"
        },
        {
          "id": "cc809ea6-7e81-34b6-af18-4835fddc904a",
          "key": "B",
          "text": "$7$"
        },
        {
          "id": "039f4868-c2c6-3306-9517-6e3187768ab7",
          "key": "C",
          "text": "$8$"
        },
        {
          "id": "881c27ed-3b82-30a7-abd1-e21c71548ddd",
          "key": "D",
          "text": "$\\sqrt{60}$"
        }
      ],
      "correct_option_id": "881c27ed-3b82-30a7-abd1-e21c71548ddd",
      "explanation": "Choice D is correct. The equation of a circle in the $xy$-plane with its center at $(0, 0)$ can be expressed as $x^2 + y^2 = r^2$, where $r$ is the radius of the circle. Since $(8, 0)$ lies on the circle, the radius of the circle is $r = 8$. Substituting $8$ for $r$ yields:\n$$x^2 + y^2 = 64$$\nIt is also given that $(2, k)$ lies on the circle. Substituting $2$ for $x$ and $k$ for $y$ yields:\n$$2^2 + k^2 = 64 \\implies 4 + k^2 = 64$$\nSubtracting $4$ from both sides yields:\n$$k^2 = 60$$\nTaking the square root of both sides yields $k = \\pm\\sqrt{60}$. Since $(2, k)$ lies above the $x$-axis, $k$ must be positive. Therefore:\n$$k = \\sqrt{60}$$",
      "content_version": 1,
      "active": true,
      "deleted": false
    }
  },
  {
    "external_key": "SAT_MATH:d6af3572",
    "image_key": "SAT_MATH/d6af3572/85090963750d1129aedcdcc642818e815d84f159934136bb97237f95b0aa84f1.png",
    "new_id": "d079660b-6153-5dde-9a0c-8794b845c578",
    "expected": {
      "id": "c84ccd61-6d0c-5443-ad00-dbf31d9b6ce4",
      "external_key": "SAT_MATH:d6af3572",
      "discipline_code": "SAT_MATH",
      "topic_code": "DATA_TWO_VARIABLES",
      "topic_name": "Problem-Solving and Data Analysis / Two-variable data: Models and scatterplots",
      "difficulty": "HARD",
      "prompt": "The scatterplot shows the federal-mandated minimum wage every 10 years between 1940 and 2010. A line of best fit is shown, and its equation is $y = 0.096x - 0.488$, where $x$ represents the number of years since 1940 and $y$ represents the minimum wage in dollars per hour. What does the line of best fit predict about the increase in the minimum wage over the 70-year period?",
      "options": [
        {
          "id": "d0c69a01-42b2-39b2-9189-01d4a5e96fea",
          "key": "A",
          "text": "Each year between 1940 and 2010, the average increase in minimum wage was 0.096 dollars."
        },
        {
          "id": "25339732-28c6-3d75-ab17-6f2840fafbdf",
          "key": "B",
          "text": "Each year between 1940 and 2010, the average increase in minimum wage was 0.49 dollars."
        },
        {
          "id": "6dc4df5c-a61f-3294-81b5-cd0cd22f48bb",
          "key": "C",
          "text": "Every 10 years between 1940 and 2010, the average increase in minimum wage was 0.096 dollars."
        },
        {
          "id": "4b9d1b76-d6a7-3194-b7a7-b14f4fcc8d83",
          "key": "D",
          "text": "Every 10 years between 1940 and 2010, the average increase in minimum wage was 0.488 dollars."
        }
      ],
      "correct_option_id": "d0c69a01-42b2-39b2-9189-01d4a5e96fea",
      "explanation": "Choice A is correct. The equation of the line of best fit is given in slope-intercept form, $y = mx + b$, where $m$ is the slope. Here, $m = 0.096$. By definition, the slope represents the change in $y$ for each 1-unit increase in $x$. Since $x$ is measured in single years and $y$ is measured in dollars per hour, the line of best fit predicts that each year between 1940 and 2010, the average increase in the minimum wage was 0.096 dollars per hour.",
      "content_version": 1,
      "active": true,
      "deleted": false
    }
  },
  {
    "external_key": "SAT_MATH:24a1e6a7",
    "image_key": "SAT_MATH/24a1e6a7/165bdad572b7717cc840b597a4e074b1f98c1a7d3f9ec55c9159432c4987edce.png",
    "new_id": "2ddc4c28-12e8-58ad-bfb5-3fc31bb99dcd",
    "expected": {
      "id": "b77a7801-fdc7-5b7a-9a87-93097926068d",
      "external_key": "SAT_MATH:24a1e6a7",
      "discipline_code": "SAT_MATH",
      "topic_code": "DATA_TWO_VARIABLES",
      "topic_name": "Problem-Solving and Data Analysis / Two-variable data: Models and scatterplots",
      "difficulty": "MEDIUM",
      "prompt": "The scatterplot shows the relationship between two variables, $x$ and $y$. A line of best fit is also shown, passing approximately through $(0, 14)$ and $(13, 0)$. Which of the following is closest to the slope of this line of best fit?",
      "options": [
        {
          "id": "8b40c9cf-fd47-3dbc-ad94-87e8b74231df",
          "key": "A",
          "text": "$-3.3$"
        },
        {
          "id": "c8f634b0-f0f4-3991-b6cc-8b4582bc8970",
          "key": "B",
          "text": "$-1.1$"
        },
        {
          "id": "e41a4f12-c5e0-3c7b-8c3e-65b40b3f1f4c",
          "key": "C",
          "text": "1.1"
        },
        {
          "id": "c87d15fe-1ff7-3b04-845b-6bb244925085",
          "key": "D",
          "text": "3.3"
        }
      ],
      "correct_option_id": "c8f634b0-f0f4-3991-b6cc-8b4582bc8970",
      "explanation": "Choice B is correct. Using the two points $(0, 14)$ and $(13, 0)$ on the line of best fit, the slope $m$ is:\n$$m = \\frac{0 - 14}{13 - 0} = -\\frac{14}{13} \\approx -1.077$$\nAmong the choices, $-1.1$ is closest to $-1.077$.",
      "content_version": 1,
      "active": true,
      "deleted": false
    }
  },
  {
    "external_key": "SAT_MATH:25fc031a",
    "image_key": "SAT_MATH/25fc031a/ce3aca6e2317790419225853fe0b13b904cfd18dea76dfcf8a1a51f61bd2f6c5.png",
    "new_id": "8d2816ac-f3d3-5cfc-b196-14c378d1f167",
    "expected": {
      "id": "26df5954-d578-5ba4-a83c-15acfd0d3b5a",
      "external_key": "SAT_MATH:25fc031a",
      "discipline_code": "SAT_MATH",
      "topic_code": "DATA_ONE_VARIABLE",
      "topic_name": "Problem-Solving and Data Analysis / One-variable data: Distributions and measures of center and spread",
      "difficulty": "MEDIUM",
      "prompt": "The histograms summarize the distributions of number of units sold, in thousands, for company A and company B. Company A has high frequencies concentrated tightly around the center ($30-35\\text{ thousand}$), whereas Company B has higher frequencies spread out toward the outer ends ($15-20$ and $45-50\\text{ thousand}$). Which statement best compares the standard deviations of number of units sold for these companies?",
      "options": [
        {
          "id": "c29edd3c-a118-3c02-870a-21231ac92a56",
          "key": "A",
          "text": "The standard deviation of number of units sold for company A is less than the standard deviation of number of units sold for company B."
        },
        {
          "id": "a883d544-f7cc-37dc-9f0e-1d0985b953b3",
          "key": "B",
          "text": "The standard deviation of number of units sold for company A is greater than the standard deviation of number of units sold for company B."
        },
        {
          "id": "c373c2e6-c910-34a9-acad-12f51246f133",
          "key": "C",
          "text": "The standard deviation of number of units sold for company A is equal to the standard deviation of number of units sold for company B."
        },
        {
          "id": "b97e521e-eb21-3fe7-be90-c4d459818419",
          "key": "D",
          "text": "There is not enough information to compare the standard deviations."
        }
      ],
      "correct_option_id": "c29edd3c-a118-3c02-870a-21231ac92a56",
      "explanation": "Choice A is correct. Standard deviation measures the spread or dispersion of a dataset around its mean.\n- Both histograms are symmetric with the same center (mean between 30 and 35 thousand).\n- In company A's histogram, data values are heavily concentrated near the mean, indicating low variability and a smaller standard deviation.\n- In company B's histogram, substantial proportions of data values are located in the outer tails farther from the mean, indicating higher variability and a larger standard deviation.\nTherefore, the standard deviation of company A is less than the standard deviation of company B.",
      "content_version": 1,
      "active": true,
      "deleted": false
    }
  },
  {
    "external_key": "SAT_MATH:3e4e2ab0",
    "image_key": "SAT_MATH/3e4e2ab0/3782c981028e31afe7e1dae99d66c4ac8ae390191d985e9261f203a2ce1f3da4.png",
    "new_id": "6ae8246b-12da-5e56-a92e-016f973e8d31",
    "expected": {
      "id": "080ef5c3-c29f-598c-98dd-40bd43444400",
      "external_key": "SAT_MATH:3e4e2ab0",
      "discipline_code": "SAT_MATH",
      "topic_code": "GEOMETRY_LINES_ANGLES_TRIANGLES",
      "topic_name": "Geometry and Trigonometry / Lines, angles, and triangles",
      "difficulty": "MEDIUM",
      "prompt": "In the figure, $\\overline{AE}$ intersects $\\overline{DB}$ at point $C$ and $\\overline{AB}$ is parallel to $\\overline{DE}$, creating triangles $ABC$ and $CDE$. In triangle $ABC$, the angle at $A$ has measure $y^\\circ$. In triangle $CDE$, angle $\\angle DCE$ has measure $x^\\circ$ and angle $\\angle CDE$ has measure $z^\\circ$. If $x = 63$ and $y = 2x - 47$, what is the value of $z$?",
      "options": [
        {
          "id": "80a5c05d-497b-3d2b-a270-830699cde594",
          "key": "A",
          "text": "38"
        },
        {
          "id": "365321ff-d36b-39c9-9054-3617f0e9490a",
          "key": "B",
          "text": "47"
        },
        {
          "id": "e4b59573-f42a-353e-8096-d3a9d6c33ddf",
          "key": "C",
          "text": "63"
        },
        {
          "id": "c4046d14-78de-39a4-a38e-68102785a9a7",
          "key": "D",
          "text": "79"
        }
      ],
      "correct_option_id": "80a5c05d-497b-3d2b-a270-830699cde594",
      "explanation": "Choice A is correct. Since $\\overline{AB} \\parallel \\overline{DE}$ with transversal $\\overline{AE}$, alternate interior angles $\\angle BAC$ and $\\angle DEC$ are congruent:\n$$m\\angle DEC = m\\angle BAC = y^\\circ$$\nWe are given that $x = 63$ and $y = 2x - 47$:\n$$y = 2(63) - 47 = 126 - 47 = 79$$\nThe interior angles of triangle $CDE$ are $\\angle DCE = x^\\circ = 63^\\circ$, $\\angle DEC = y^\\circ = 79^\\circ$, and $\\angle CDE = z^\\circ$. The angles of a triangle sum to $180^\\circ$:\n$$63 + 79 + z = 180 \\implies 142 + z = 180 \\implies z = 38$$",
      "content_version": 1,
      "active": true,
      "deleted": false
    }
  },
  {
    "external_key": "SAT_MATH:50b2807e",
    "image_key": "SAT_MATH/50b2807e/f1c01d587e5be837feacf28049693a5bd886f99e5d977567cf60abd42c8905e1.png",
    "new_id": "66a2e2c3-3cf1-5efd-b347-9616057810aa",
    "expected": {
      "id": "06573038-109d-5929-bfb4-d1e5e9eb4e5e",
      "external_key": "SAT_MATH:50b2807e",
      "discipline_code": "SAT_MATH",
      "topic_code": "DATA_TWO_VARIABLES",
      "topic_name": "Problem-Solving and Data Analysis / Two-variable data: Models and scatterplots",
      "difficulty": "MEDIUM",
      "prompt": "The scatterplot shows the relationship between two variables, $x$ and $y$. As $x$ increases from 1 to 10, $y$ decreases from approximately 9 to approximately 1. Which of the following equations is the most appropriate linear model for the data shown?",
      "options": [
        {
          "id": "0d0bd530-75ef-3a16-aa52-1235f4a59cdf",
          "key": "A",
          "text": "$y = 0.9 + 9.4x$"
        },
        {
          "id": "b4813cf1-4553-3dcb-bc90-c6efd546e521",
          "key": "B",
          "text": "$y = 0.9 - 9.4x$"
        },
        {
          "id": "1e762cd8-6554-3659-b37a-72568c680d67",
          "key": "C",
          "text": "$y = 9.4 + 0.9x$"
        },
        {
          "id": "28a8e528-5607-3f3d-b2bb-6b2a49e4c5b7",
          "key": "D",
          "text": "$y = 9.4 - 0.9x$"
        }
      ],
      "correct_option_id": "28a8e528-5607-3f3d-b2bb-6b2a49e4c5b7",
      "explanation": "Choice D is correct. Looking at the scatterplot:\n- As $x$ increases, $y$ decreases, which indicates a negative slope ($b < 0$).\n- When $x = 0$, the $y$-intercept is above $9$ (approximately $9.4$).\nAmong the given options:\n- Choices A and C have positive slopes.\n- Choice B has a $y$-intercept of $0.9$, which is far too low.\n- Choice D has a $y$-intercept of $9.4$ and a negative slope of $-0.9$, fitting the data points: for example, when $x = 5$, $y \\approx 9.4 - 0.9(5) = 4.9$, matching the observed point $(5, 5)$.",
      "content_version": 1,
      "active": true,
      "deleted": false
    }
  },
  {
    "external_key": "SAT_MATH:659cb706",
    "image_key": "SAT_MATH/659cb706/75182ae0086097e92b3479e755f470dd7d583bdb441de7b263da2e0c2e85238b.png",
    "new_id": "f3ebea2d-20de-5c4e-aaa1-b50ab8f53ac0",
    "expected": {
      "id": "e5c13f4a-bbe7-57b3-9d68-261a0aeb212f",
      "external_key": "SAT_MATH:659cb706",
      "discipline_code": "SAT_MATH",
      "topic_code": "GEOMETRY_RIGHT_TRIANGLES_TRIGONOMETRY",
      "topic_name": "Geometry and Trigonometry / Right triangles and trigonometry",
      "difficulty": "MEDIUM",
      "prompt": "Triangle $XYZ$ shown is a right triangle with right angle at $Z$, leg $XZ = 27$, and leg $YZ = 35$. Which of the following has the same value as $\\sin X$?",
      "options": [
        {
          "id": "f4346f37-0e98-3b5c-970b-3a710480823f",
          "key": "A",
          "text": "$\\tan X$"
        },
        {
          "id": "e21d1374-3ab6-383a-be50-9e2d85d5a15a",
          "key": "B",
          "text": "$\\tan Y$"
        },
        {
          "id": "5e7e42cb-41ae-397d-b2e8-cc11ca2645bc",
          "key": "C",
          "text": "$\\cos X$"
        },
        {
          "id": "cee862b0-9035-3688-b7cb-7c8e1d3b6e03",
          "key": "D",
          "text": "$\\cos Y$"
        }
      ],
      "correct_option_id": "cee862b0-9035-3688-b7cb-7c8e1d3b6e03",
      "explanation": "Choice D is correct. In a right triangle, the two acute angles are complementary: $m\\angle X + m\\angle Y = 90^\\circ$. By trigonometric cofunction identities, the sine of an acute angle is always equal to the cosine of its complement:\n$$\\sin X = \\frac{\\text{opposite}}{\\text{hypotenuse}} = \\frac{YZ}{XY} = \\cos Y$$\nTherefore, $\\cos Y$ has the same value as $\\sin X$.",
      "content_version": 1,
      "active": true,
      "deleted": false
    }
  },
  {
    "external_key": "SAT_MATH:9b0a4eae",
    "image_key": "SAT_MATH/9b0a4eae/3cf2b90de10f60667363eac0d1cfc325ca23bf4bae23306600b5d46c5da4e9a4.png",
    "new_id": "ba4c40d4-6c6f-5aef-9cef-ae6ded1b894f",
    "expected": {
      "id": "9607f33a-ada1-5ac8-a086-3ade45910d14",
      "external_key": "SAT_MATH:9b0a4eae",
      "discipline_code": "SAT_MATH",
      "topic_code": "ALGEBRA_LINEAR_TWO_VARIABLES",
      "topic_name": "Algebra / Linear equations in two variables",
      "difficulty": "MEDIUM",
      "prompt": "The graph in the $xy$-plane models the possible combinations of length $x$, in meters ($\text{m}$), and width $y$, in meters, for a rectangle with a perimeter of $36\\text{ m}$. Which statement is the best interpretation of the point $(8, 10)$ in this context?",
      "options": [
        {
          "id": "180a5618-9457-3606-9e4a-eb950a4e6512",
          "key": "A",
          "text": "The length is $10\\text{ m}$ less than the perimeter, and the width is $8\\text{ m}$ less than the perimeter."
        },
        {
          "id": "2d6ff3e0-b8aa-331b-acf0-f871c8aad229",
          "key": "B",
          "text": "The length is $10\\text{ m}$, and the width is $8\\text{ m}$."
        },
        {
          "id": "d781cfe4-3658-3ccf-90c0-999a6aeb02ce",
          "key": "C",
          "text": "The length is $8\\text{ m}$, and the width is $10\\text{ m}$."
        },
        {
          "id": "b3abd8bc-6f16-3219-ab9e-b09c543228f2",
          "key": "D",
          "text": "The length is $8\\text{ m}$ less than the perimeter, and the width is $10\\text{ m}$ less than the perimeter."
        }
      ],
      "correct_option_id": "d781cfe4-3658-3ccf-90c0-999a6aeb02ce",
      "explanation": "Choice C is correct. In this context, $x$ represents the length of the rectangle in meters and $y$ represents the width of the rectangle in meters. Thus, the coordinate $(8, 10)$ means that the rectangle has a length of $8\\text{ m}$ and a width of $10\\text{ m}$.",
      "content_version": 1,
      "active": true,
      "deleted": false
    }
  },
  {
    "external_key": "SAT_MATH:ecc98c87",
    "image_key": "SAT_MATH/ecc98c87/7b8fa32e074b64881b49236b7da50a92055e2ce7a7048f5df96517168e3d0617.png",
    "new_id": "4c80b1c1-b8d8-58ba-93c8-7d87cc86c553",
    "expected": {
      "id": "741a8c76-8242-5d11-8a08-f6418e71e985",
      "external_key": "SAT_MATH:ecc98c87",
      "discipline_code": "SAT_MATH",
      "topic_code": "GEOMETRY_LINES_ANGLES_TRIANGLES",
      "topic_name": "Geometry and Trigonometry / Lines, angles, and triangles",
      "difficulty": "MEDIUM",
      "prompt": "In the figure shown, line $k$ intersects lines $r$ and $s$. At the intersection with line $r$, the angles are $w^\\circ$ and $x^\\circ$. At the intersection with line $s$, the angles are $y^\\circ$ and $z^\\circ$. If $w = 147$, which additional piece of information is sufficient to prove that lines $r$ and $s$ are parallel?",
      "options": [
        {
          "id": "772d7923-e3b4-39b8-b412-67cea2d78da7",
          "key": "A",
          "text": "$x = 33$"
        },
        {
          "id": "8253aa0f-f0f3-3f28-8d32-977795035f81",
          "key": "B",
          "text": "$y = 147$"
        },
        {
          "id": "e39fc8f3-493c-3460-8f1a-9b8ef3e701fa",
          "key": "C",
          "text": "$w + y = 180$"
        },
        {
          "id": "0408d712-89b2-3531-88b2-7329bf7546e7",
          "key": "D",
          "text": "$y + z = 180$"
        }
      ],
      "correct_option_id": "8253aa0f-f0f3-3f28-8d32-977795035f81",
      "explanation": "Choice B is correct. In the figure, the angles labeled $w^\\circ$ and $y^\\circ$ occupy the same relative position at each intersection, making them corresponding angles. Lines $r$ and $s$ cut by transversal $k$ are parallel if and only if corresponding angles are congruent ($w = y$). Since $w = 147$, knowing that $y = 147$ establishes that $w = y$, which is sufficient to prove that lines $r$ and $s$ are parallel.",
      "content_version": 1,
      "active": true,
      "deleted": false
    }
  },
  {
    "external_key": "SAT_RW:a15b3219",
    "image_key": "SAT_RW/a15b3219/b61ffefd1f32186b69ee8d6bf4fc841c320a14642d672494226432d1b478f513.png",
    "new_id": "4aff7f26-b241-57cd-aed4-bb45de35916e",
    "expected": {
      "id": "13809116-e088-5fc7-b7a2-6960f4d4f5ef",
      "external_key": "SAT_RW:a15b3219",
      "discipline_code": "SAT_RW",
      "topic_code": "INFORMATION_COMMAND_OF_EVIDENCE",
      "topic_name": "Information and Ideas / Command of Evidence",
      "difficulty": "HARD",
      "prompt": "**Municipalities’ Responses to Inquiries about Potential Incentives for Firm**\n*(Data from Graph: Number of municipalities surveyed)*\n- **No response:** Announcement before election (~1,250); Announcement after election (~1,240)\n- **Responded to inquiry:** Announcement before election (~200); Announcement after election (~200)\n- **Offered incentive:** Announcement before election (~100); Announcement after election (~100)\n\nIn the United States, firms often seek incentives from municipal governments to expand to those municipalities. A team of political scientists hypothesized that municipalities are much more likely to respond to firms and offer incentives if expansions can be announced in time to benefit local elected officials than if they can’t. The team contacted officials in thousands of municipalities, inquiring about incentives for a firm looking to expand and indicating that the firm would announce its expansion on a date either just before or just after the next election.\n\nWhich choice best describes data from the graph that weaken the team’s hypothesis?",
      "options": [
        {
          "id": "b1834537-8bb4-390d-a676-7f1fa79fe817",
          "key": "A",
          "text": "A large majority of the municipalities that received an inquiry mentioning plans for an announcement before the next election didn’t respond to the inquiry."
        },
        {
          "id": "30eadb36-61aa-3efe-9673-71483e212297",
          "key": "B",
          "text": "The proportion of municipalities that responded to the inquiry or offered incentives didn’t substantially differ across the announcement timing conditions."
        },
        {
          "id": "b4c091e4-4f1c-3e2b-ba8e-728dbe278e18",
          "key": "C",
          "text": "Only around half the municipalities that responded to inquiries mentioning plans for an announcement before the next election offered incentives."
        },
        {
          "id": "1d2288ef-c203-3d17-9e59-27e513454ab3",
          "key": "D",
          "text": "Of the municipalities that received an inquiry mentioning plans for an announcement date after the next election, more than 1,200 didn’t respond and only around 100 offered incentives."
        }
      ],
      "correct_option_id": "30eadb36-61aa-3efe-9673-71483e212297",
      "explanation": "Choice B is the best answer. The text explains that firms in the United States often look to municipal governments (local governing bodies) for incentives to expand the firms into those areas. The text then indicates that a team of political scientists hypothesized that those governing bodies are much more likely to respond and offer incentives when the expansion (if there’s going to be one) can be announced before an election, since announcing a firm coming to their area can benefit local elected officials. However, the graph—which presents the results of the political scientists’ inquiries to municipalities about incentives for a firm in two timing scenarios—shows that the proportion of municipalities that responded to the inquiry or offered incentives didn’t substantially differ based on timing. According to the graph, about 200 municipalities responded to the inquiry and about 100 offered an incentive when the announcement could be made before an election (represented by the gray bars) and about 200 municipalities responded to the inquiry and about 100 offered an incentive when the announcement would be made after an election (represented by the black bars). These data weaken the team’s hypothesis by demonstrating that municipalities are not much more likely to respond and offer incentives when the timing means they could announce an expansion before an election.\n\nChoice A is incorrect. Although the graph does show that a large number of municipalities didn’t respond to inquiries in the scenario in which an expansion announcement could be made before an election (represented by the gray bars), the text indicates that the team hypothesized that there would be a substantial difference in municipalities’ actions based on timing, and information about only one timing scenario doesn’t reveal anything about whether such a difference occurred. Choice C is incorrect. The graph does show that in the scenario in which an expansion announcement could be made before an election (represented by the gray bars), about 200 municipalities responded to inquiries and about 100 offered an incentive, but the text indicates that the team hypothesized that there would be a substantial difference in municipalities’ actions based on timing, and information about only one timing scenario doesn’t reveal anything about whether such a difference occurred. Choice D is incorrect. Although this choice accurately describes data from the graph for the scenario in which an expansion announcement would be made after an election (represented by the black bars), the text indicates that the team hypothesized that there would be a substantial difference in municipalities’ actions based on timing, and information about only one timing scenario doesn’t reveal anything about whether such a difference occurred.",
      "content_version": 1,
      "active": true,
      "deleted": false
    }
  },
  {
    "external_key": "SAT_RW:d83c3d54",
    "image_key": "SAT_RW/d83c3d54/f44ac4e6ef69960fdf82b6a3b1f3594a40f4a05dd007e4bbecc95dc56250203e.png",
    "new_id": "cf2456e1-99eb-59db-88c7-3e92101b669e",
    "expected": {
      "id": "c6d8e6ed-b780-5e21-b4c2-87135d2687ca",
      "external_key": "SAT_RW:d83c3d54",
      "discipline_code": "SAT_RW",
      "topic_code": "INFORMATION_COMMAND_OF_EVIDENCE",
      "topic_name": "Information and Ideas / Command of Evidence",
      "difficulty": "MEDIUM",
      "prompt": "**Characteristics of the Banks of the Provo River Downstream of the Jordanelle Dam**\n*(Data from Graph: Area in square meters across years)*\n- **1987 (Before dam):** Grass cover: ~58,000 m²; Bare soil: ~65,000 m²; Forest cover: ~75,000 m²\n- **1993 (After dam):** Grass cover: ~95,000 m²; Bare soil: ~18,000 m²; Forest cover: ~58,000 m²\n- **2006 (After dam):** Grass cover: ~130,000 m²; Bare soil: ~35,000 m²; Forest cover: ~45,000 m²\n\nThe Jordanelle Dam was built on the Provo River in Utah in 1992. Earth scientist Adriana E. Martinez and colleagues tracked changes to the environment on the banks of the river downstream of the dam, including how much grass and forest cover were present. They concluded that the dam changed the flow of the river in ways that benefited grass plants but didn’t benefit trees.\n\nWhich choice best describes data from the graph that support Martinez and colleagues’ conclusion?",
      "options": [
        {
          "id": "7f8986ed-411d-3865-968d-b928474a20e3",
          "key": "A",
          "text": "The lowest amount of grass cover was approximately 58,000 square meters, and the highest amount of forest cover was approximately 75,000 square meters."
        },
        {
          "id": "2813f04b-0e69-32cb-a5bb-5812680a9b97",
          "key": "B",
          "text": "There was more grass cover than forest cover in 1987, and this difference increased dramatically in 1993 and again in 2006."
        },
        {
          "id": "170ed21c-5c4f-3047-931c-20a329ade033",
          "key": "C",
          "text": "There was less grass cover than bare soil in 1987 but more grass cover than bare soil in 1993 and 2006, whereas there was more forest cover than bare soil in all three years."
        },
        {
          "id": "bc1678e7-7bc8-3f4f-aac3-a1e487e68972",
          "key": "D",
          "text": "Grass cover increased from 1987 to 1993 and from 1993 to 2006, whereas forest cover decreased in those periods."
        }
      ],
      "correct_option_id": "bc1678e7-7bc8-3f4f-aac3-a1e487e68972",
      "explanation": "Choice D is the best answer because it describes data from the graph that support Martinez and colleagues’ conclusion that the Jordanelle Dam led to changes that benefited grass plants but not trees. The graph shows characteristics of the banks of the Provo River downstream of the Jordanelle Dam in three different years—1987, 1993, and 2006. Specifically, the graph shows the amount of grass cover, bare soil, and forest cover in those years. The text indicates that the Jordanelle Dam was built in 1992, meaning that the data from the graph for 1987 reflect conditions before the dam was built, whereas the data for 1993 and 2006 reflect conditions after the dam was built. The data show that grass cover increased substantially from 1987 to 1993 and again from 1993 to 2006. The data also show that forest cover declined over those periods. Together, these data support Martinez and colleagues’ conclusion that the dam was beneficial for grass plants but not for trees—grass cover increased significantly after the dam was built, while forest cover declined.\n\nChoice A is incorrect. Although it is true that, in the graph, the lowest value for grass cover is approximately 58,000 square meters and the highest value for forest cover is approximately 75,000 square meters, both values are from 1987, before the Jordanelle Dam was built in 1992. Therefore, this information alone cannot support Martinez and colleagues’ conclusion about changes in grass and tree cover following the construction of the dam. Choice B is incorrect because it presents an inaccurate description of data from the graph. The graph shows that there was more forest cover than grass cover in 1987, not that there was more grass cover than forest cover that year. Choice C is incorrect because, while it accurately reflects data from the graph when it compares grass cover and forest cover to bare soil, these data alone cannot support Martinez and colleagues’ conclusion that the dam led to changes that benefited grass plants but not trees. An increase in grass cover relative to bare soil following the construction of the dam might indicate that the dam benefited grass plants, but the fact that there was more forest cover than bare soil in all three years doesn’t indicate that the dam failed to benefit trees.",
      "content_version": 1,
      "active": true,
      "deleted": false
    }
  }
]
$question_images$::jsonb) AS s(external_key text, image_key text, new_id uuid, expected jsonb);

-- Fail atomically for an altered, missing or newer source; never downgrade custom content.
DO $$ BEGIN
    IF (SELECT count(*) FROM question_image_seed) <> 22
       OR (SELECT count(DISTINCT external_key) FROM question_image_seed) <> 22 THEN
        RAISE EXCEPTION 'Question image seed must contain 22 distinct READY bindings';
    END IF;
    IF EXISTS (
        SELECT 1 FROM question_image_seed s
        WHERE (SELECT count(*) FROM questions q WHERE q.external_key=s.external_key) <> 1
           OR NOT EXISTS (SELECT 1 FROM questions q WHERE q.external_key=s.external_key
                          AND to_jsonb(q) @> s.expected AND q.image_key IS NULL)
           OR EXISTS (SELECT 1 FROM questions q WHERE q.id=s.new_id)
    ) THEN
        RAISE EXCEPTION 'Question image seed conflicts with expected V12 revision 1; no content was changed';
    END IF;
END $$;

UPDATE questions q SET active=false, updated_at=timezone('UTC',now())
FROM question_image_seed s WHERE q.external_key=s.external_key AND q.content_version=1;

-- Preserve option UUIDs and correct mapping along with all original authored content.
INSERT INTO questions(id,created_at,updated_at,deleted,external_key,content_version,
    discipline_code,topic_code,topic_name,difficulty,prompt,options,correct_option_id,
    explanation,active,image_key)
SELECT s.new_id,timezone('UTC',now()),timezone('UTC',now()),false,q.external_key,2,
    q.discipline_code,q.topic_code,q.topic_name,q.difficulty,q.prompt,q.options,q.correct_option_id,
    q.explanation,true,s.image_key
FROM question_image_seed s JOIN questions q ON q.external_key=s.external_key AND q.content_version=1;
